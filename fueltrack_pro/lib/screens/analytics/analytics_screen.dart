import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/fuel_calculations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../refuel/add_refuel_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final refuelsAsync = ref.watch(refuelsProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final currency = settings?.currencyCode ?? 'OMR';
    final fuelUnit = settings?.fuelUnit.abbreviation ?? 'L';
    final period = ref.watch(analyticsPeriodProvider);

    return refuelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allRefuels) {
        if (allRefuels.isEmpty) {
          return EmptyState(
            icon: Icons.insights_outlined,
            title: 'No analytics yet',
            message:
                'Log a few refuels to unlock efficiency trends, spending charts, and fleet insights.',
            actionLabel: 'Log Refuel',
            onAction: () => AddRefuelScreen.open(context),
          );
        }

        return analyticsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stats) {
            if (stats.entries.isEmpty) {
              return Column(
                children: [
                  _AnalyticsHeader(period: period, onPeriodChanged: (p) {
                    ref.read(analyticsPeriodProvider.notifier).state = p;
                  }),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.date_range_outlined,
                      title: 'No data for ${period.label.toLowerCase()} view',
                      message:
                          'Try a longer period or log more refuels in this timeframe.',
                    ),
                  ),
                ],
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(analyticsProvider),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        AppSpacing.stackLg,
                        AppSpacing.marginMobile,
                        AppSpacing.stackMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Analytics',
                            style: context.tt.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time breakdown of efficiency and spending for ${period.label.toLowerCase()} view.',
                            style: context.tt.bodyMedium?.copyWith(
                              color: context.cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.stackLg),
                          _PeriodSelector(
                            selected: period,
                            onChanged: (p) {
                              ref.read(analyticsPeriodProvider.notifier).state =
                                  p;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      0,
                      AppSpacing.marginMobile,
                      120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _EfficiencyTrendCard(
                          trips: stats.trips,
                          peakKmPerLiter: stats.peakKmPerLiter,
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _EfficiencyInsightCard(
                                changePercent: stats.efficiencyChangePercent,
                                avgKmPerLiter: stats.avgKmPerLiter,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.gutter),
                            Expanded(
                              child: _CostInsightCard(
                                costPerKm: stats.costPerKm,
                                currency: currency,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        _MonthlySpendingCard(
                          monthly: stats.monthlySpending,
                          currency: currency,
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _FuelSharePieCard(
                                vehicleShares: stats.vehicleShares,
                                totalLiters: stats.totalLiters,
                                fuelUnit: fuelUnit,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.gutter),
                            Expanded(
                              child: _EfficiencyMetricsCard(
                                avgKmPerLiter: stats.avgKmPerLiter,
                                litersPer100Km: stats.litersPer100Km,
                                totalLiters: stats.totalLiters,
                                totalSpent: stats.totalSpent,
                                currency: currency,
                                fuelUnit: fuelUnit,
                              ),
                            ),
                          ],
                        ),
                        if (stats.vehicleProfiles.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.stackLg),
                          Text(
                            'Vehicle Profiles',
                            style: context.tt.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          ...stats.vehicleProfiles.map(
                            (profile) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.gutter,
                              ),
                              child: _VehicleProfileCard(profile: profile),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.period,
    required this.onPeriodChanged,
  });

  final AnalyticsPeriod period;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      child: _PeriodSelector(selected: period, onChanged: onPeriodChanged),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AnalyticsPeriod.values.map((period) {
        return SelectionChip(
          label: period.label,
          compact: true,
          selected: selected == period,
          onTap: () => onChanged(period),
        );
      }).toList(),
    );
  }
}

/// Shared shell for the surface-colored analytics cards.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _EfficiencyTrendCard extends StatelessWidget {
  const _EfficiencyTrendCard({
    required this.trips,
    required this.peakKmPerLiter,
  });

  final List<TripEfficiency> trips;
  final double? peakKmPerLiter;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel Consumption Trends',
                      style: tt.titleMedium,
                    ),
                    Text(
                      'Historical km/L performance',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'km/L',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          if (trips.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: Text('Need 2+ refuels for trends')),
            )
          else
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      minY: _minY(trips),
                      maxY: _maxY(trips),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        leftTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < trips.length; i++)
                              FlSpot(i.toDouble(), trips[i].kmPerLiter),
                          ],
                          isCurved: true,
                          color: cs.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: cs.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (peakKmPerLiter != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Peak: ${peakKmPerLiter!.toStringAsFixed(1)} km/L',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _minY(List<TripEfficiency> trips) {
    final min = trips.map((t) => t.kmPerLiter).reduce((a, b) => a < b ? a : b);
    return (min * 0.85).floorToDouble();
  }

  double _maxY(List<TripEfficiency> trips) {
    final max = trips.map((t) => t.kmPerLiter).reduce((a, b) => a > b ? a : b);
    return (max * 1.15).ceilToDouble();
  }
}

class _EfficiencyInsightCard extends StatelessWidget {
  const _EfficiencyInsightCard({
    required this.changePercent,
    required this.avgKmPerLiter,
  });

  final double? changePercent;
  final double? avgKmPerLiter;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final improved = (changePercent ?? 0) >= 0;
    final headline = changePercent != null
        ? '${improved ? 'Improved' : 'Down'} ${changePercent!.abs().toStringAsFixed(0)}%'
        : avgKmPerLiter != null
            ? '${avgKmPerLiter!.toStringAsFixed(1)} km/L'
            : '—';

    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(
              improved ? Icons.trending_up : Icons.trending_down,
              size: 72,
              color: cs.onPrimaryContainer.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt, color: cs.onPrimaryContainer),
              Text(
                'Efficiency Gain',
                style: tt.titleSmall?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Text(
                headline,
                style: tt.headlineSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                changePercent != null
                    ? 'Earlier vs later trips in period'
                    : 'Average efficiency',
                style: tt.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostInsightCard extends StatelessWidget {
  const _CostInsightCard({
    required this.costPerKm,
    required this.currency,
  });

  final double? costPerKm;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments, color: cs.onSecondaryContainer),
          Text(
            'Cost Metric',
            style: tt.titleSmall?.copyWith(
              color: cs.onSecondaryContainer.withValues(alpha: 0.9),
            ),
          ),
          const Spacer(),
          Text(
            costPerKm != null ? costPerKm!.toStringAsFixed(3) : '—',
            style: tt.headlineSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Average cost per km ($currency)',
            style: tt.labelMedium?.copyWith(
              color: cs.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySpendingCard extends StatelessWidget {
  const _MonthlySpendingCard({
    required this.monthly,
    required this.currency,
  });

  final List<MonthlySpendPoint> monthly;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Spending', style: tt.titleMedium),
          Text(
            'Last 3 months (fuel only)',
            style: tt.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          if (monthly.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('No spending data yet')),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: monthly
                          .map((m) => m.amount)
                          .reduce((a, b) => a > b ? a : b) *
                      1.25,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthly.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthly[index].label.toUpperCase(),
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: index == monthly.length - 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < monthly.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: monthly[i].amount,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            color: i == monthly.length - 1
                                ? cs.secondary
                                : cs.secondary.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FuelSharePieCard extends StatelessWidget {
  const _FuelSharePieCard({
    required this.vehicleShares,
    required this.totalLiters,
    required this.fuelUnit,
  });

  final List<VehicleFuelShare> vehicleShares;
  final double totalLiters;
  final String fuelUnit;

  static const _colors = [
    AppColors.secondary,
    AppColors.primaryFixedDim,
    AppColors.tertiary,
    AppColors.primaryContainer,
  ];

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle Fuel Share', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.stackMd),
          if (vehicleShares.isEmpty)
            const SizedBox(
              height: 140,
              child: Center(child: Text('No fuel data')),
            )
          else ...[
            SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: [
                    for (var i = 0; i < vehicleShares.length; i++)
                      PieChartSectionData(
                        value: vehicleShares[i].liters,
                        color: _colors[i % _colors.length],
                        radius: 28,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
            ),
            Center(
              child: Text(
                '${totalLiters.toStringAsFixed(0)} $fuelUnit total',
                style: tt.labelLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            ...vehicleShares.take(3).map((share) {
              final index = vehicleShares.indexOf(share);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[index % _colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        share.vehicle.displayName,
                        style: tt.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${share.percent.toStringAsFixed(0)}%',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _EfficiencyMetricsCard extends StatelessWidget {
  const _EfficiencyMetricsCard({
    required this.avgKmPerLiter,
    required this.litersPer100Km,
    required this.totalLiters,
    required this.totalSpent,
    required this.currency,
    required this.fuelUnit,
  });

  final double? avgKmPerLiter;
  final double? litersPer100Km;
  final double totalLiters;
  final double totalSpent;
  final String currency;
  final String fuelUnit;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Period Summary', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.stackMd),
          _MetricRow(
            label: 'Avg efficiency',
            value: avgKmPerLiter != null
                ? '${avgKmPerLiter!.toStringAsFixed(1)} km/L'
                : '—',
          ),
          _MetricRow(
            label: 'L/100km',
            value: litersPer100Km != null
                ? litersPer100Km!.toStringAsFixed(1)
                : '—',
          ),
          _MetricRow(
            label: 'Fuel used',
            value: '${totalLiters.toStringAsFixed(1)} $fuelUnit',
          ),
          _MetricRow(
            label: 'Total spend',
            value: '$currency ${totalSpent.toStringAsFixed(3)}',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.tt.bodySmall?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: context.tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleProfileCard extends StatelessWidget {
  const _VehicleProfileCard({required this.profile});

  final VehicleAnalytics profile;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final vehicle = profile.vehicle;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(
              Icons.directions_car_filled_outlined,
              color: cs.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.fuelType.label.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(vehicle.displayName, style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(
                  profile.avgKmPerLiter != null
                      ? 'Avg. ${profile.avgKmPerLiter!.toStringAsFixed(1)} km/L'
                      : 'Need more refuels',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
