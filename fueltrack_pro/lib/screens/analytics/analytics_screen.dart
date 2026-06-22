import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/fuel_calculations.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/fuel_type_metrics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/fuel_chart_style.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/active_vehicle_bar.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
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
    final period = ref.watch(analyticsPeriodProvider);
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];

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
                            'Analytics',
                            style: context.tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Efficiency and spending for ${period.label.toLowerCase()} view.',
                            style: context.tt.bodyMedium?.copyWith(
                              color: context.cs.onSurfaceVariant,
                            ),
                          ),
                          ActiveVehicleBar(
                            vehicles: vehicles,
                            embedded: true,
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
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
                          fuelType: stats.fuelType,
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _EfficiencyInsightCard(
                                changePercent: stats.efficiencyChangePercent,
                                avgKmPerLiter: stats.avgKmPerLiter,
                                fuelType: stats.fuelType,
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
                                fuelType: stats.fuelType,
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
                                fuelType: stats.fuelType,
                              ),
                            ),
                          ],
                        ),
                        if (stats.vehicleProfiles.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.stackLg),
                          Text(
                            'Vehicle Profiles',
                            style: context.tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
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

/// Shared shell for analytics cards (Wealth Journal AppCard).
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title, this.subtitle});

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            SectionHeader(title: title!, subtitle: subtitle),
            const SizedBox(height: AppSpacing.stackMd),
          ],
          child,
        ],
      ),
    );
  }
}

class _EfficiencyTrendCard extends StatelessWidget {
  const _EfficiencyTrendCard({
    required this.trips,
    required this.peakKmPerLiter,
    required this.fuelType,
  });

  final List<TripEfficiency> trips;
  final double? peakKmPerLiter;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final lineColor = pal.efficiency;
    final unit = FuelTypeMetrics.efficiencyUnit(fuelType);

    return _SectionCard(
      title: 'Consumption Trends',
      subtitle: 'Historical $unit performance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: lineColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unit,
                style: tt.labelSmall?.copyWith(
                  color: lineColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
                      gridData: FuelChartStyle.horizontalGrid(cs),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        leftTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                      ),
                      lineBarsData: [
                        FuelChartStyle.primarySeries(
                          spots: [
                            for (var i = 0; i < trips.length; i++)
                              FlSpot(i.toDouble(), trips[i].kmPerLiter),
                          ],
                          color: lineColor,
                          barWidth: FuelChartStyle.barWidthFull,
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
                          color: lineColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Peak: ${peakKmPerLiter!.toStringAsFixed(1)} $unit',
                          style: tt.labelSmall?.copyWith(
                            color: Colors.white,
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
    required this.fuelType,
  });

  final double? changePercent;
  final double? avgKmPerLiter;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final improved = (changePercent ?? 0) >= 0;
    final trendColor = improved ? pal.gain : pal.loss;
    final headline = changePercent != null
        ? '${improved ? 'Improved' : 'Down'} ${changePercent!.abs().toStringAsFixed(0)}%'
        : FuelTypeMetrics.formatEfficiency(avgKmPerLiter, fuelType);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 132,
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -8,
              child: Icon(
                improved ? Icons.trending_up : Icons.trending_down,
                size: 72,
                color: trendColor.withValues(alpha: 0.12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt, color: pal.efficiency, size: 20),
                Text(
                  'Efficiency Gain',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  headline,
                  style: tt.titleLarge?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  changePercent != null
                      ? 'Earlier vs later trips in period'
                      : 'Average efficiency',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
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

    final pal = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.payments, color: pal.spend, size: 20),
            Text(
              'Cost Metric',
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              costPerKm != null ? costPerKm!.toStringAsFixed(3) : '—',
              style: tt.titleLarge?.copyWith(
                color: pal.spend,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Average cost per km ($currency)',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
    final pal = context.palette;

    return _SectionCard(
      title: 'Monthly Spending',
      subtitle: 'Last 3 months (fuel only)',
      child: monthly.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('No spending data yet')),
            )
          : SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: monthly
                          .map((m) => m.amount)
                          .reduce((a, b) => a > b ? a : b) *
                      1.15,
                  gridData: FuelChartStyle.horizontalGrid(cs),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthly.length) {
                            return const SizedBox.shrink();
                          }
                          final isLast = index == monthly.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              monthly[index].label.toUpperCase(),
                              style: tt.labelSmall?.copyWith(
                                color: isLast
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                                fontWeight: isLast
                                    ? FontWeight.w700
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
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                            color: i == monthly.length - 1
                                ? pal.spend
                                : pal.spend.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FuelSharePieCard extends StatelessWidget {
  const _FuelSharePieCard({
    required this.vehicleShares,
    required this.totalLiters,
    required this.fuelType,
  });

  final List<VehicleFuelShare> vehicleShares;
  final double totalLiters;
  final FuelType fuelType;

  List<Color> _pieColors(BuildContext context) {
    final pal = context.palette;
    final cs = context.cs;
    return [
      pal.spend,
      pal.fuel,
      pal.efficiency,
      cs.primary,
      pal.neutral,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final colors = _pieColors(context);
    final qtyUnit = FuelTypeMetrics.quantityUnit(fuelType);

    return _SectionCard(
      title: 'Vehicle Fuel Share',
      child: vehicleShares.isEmpty
          ? const SizedBox(
              height: 140,
              child: Center(child: Text('No fuel data')),
            )
          : Column(
              children: [
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
                            color: colors[i % colors.length],
                            radius: 28,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${totalLiters.toStringAsFixed(0)} $qtyUnit total',
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
                            color: colors[index % colors.length],
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
    required this.fuelType,
  });

  final double? avgKmPerLiter;
  final double? litersPer100Km;
  final double totalLiters;
  final double totalSpent;
  final String currency;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final qtyUnit = FuelTypeMetrics.quantityUnit(fuelType);
    final consUnit = FuelTypeMetrics.consumptionPer100Unit(fuelType);

    return _SectionCard(
      title: 'Period Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'Avg efficiency',
            value: FuelTypeMetrics.formatEfficiency(avgKmPerLiter, fuelType),
          ),
          _MetricRow(
            label: consUnit,
            value: litersPer100Km != null
                ? litersPer100Km!.toStringAsFixed(1)
                : '—',
          ),
          _MetricRow(
            label: 'Energy used',
            value: '${totalLiters.toStringAsFixed(1)} $qtyUnit',
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
    final pal = context.palette;
    final vehicle = profile.vehicle;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: pal.fuel.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(
              Icons.directions_car_filled_outlined,
              color: pal.fuel,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  vehicle.displayName,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.avgKmPerLiter != null
                      ? 'Avg. ${FuelTypeMetrics.formatEfficiency(profile.avgKmPerLiter, vehicle.fuelType)}'
                      : 'Need more refuels',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pal.efficiency,
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
