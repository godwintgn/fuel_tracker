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
import '../../widgets/common/summary_header_card.dart';
import '../../widgets/common/summary_stat.dart';
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
                  _AnalyticsHeader(
                    period: period,
                    onPeriodChanged: (p) {
                      ref.read(analyticsPeriodProvider.notifier).state = p;
                    },
                  ),
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.stackMd,
                      AppSpacing.marginMobile,
                      120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Header card ────────────────────────────────────
                        SummaryHeaderCard(
                          icon: Icons.insights_outlined,
                          title: 'Analytics',
                          headlineValue: FuelTypeMetrics.formatEfficiency(
                            stats.avgKmPerLiter,
                            stats.fuelType,
                          ),
                          subtitle: 'Avg efficiency · ${period.label}',
                          trailing: SizedBox(
                            width: 200,
                            child: ActiveVehicleBar(
                              vehicles: vehicles,
                              embedded: true,
                            ),
                          ),
                          stats: [
                            SummaryStat(
                              label: 'Spend',
                              value:
                                  '$currency ${stats.totalSpent.toStringAsFixed(2)}',
                              color: context.palette.spend,
                            ),
                            SummaryStat(
                              label: 'Fills',
                              value: '${stats.entries.length}',
                            ),
                            if (stats.efficiencyChangePercent != null)
                              SummaryStat(
                                label: 'Change',
                                value:
                                    '${(stats.efficiencyChangePercent! >= 0 ? '+' : '')}${stats.efficiencyChangePercent!.toStringAsFixed(0)}%',
                                color: (stats.efficiencyChangePercent! >= 0)
                                    ? context.palette.gain
                                    : context.palette.loss,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.stackMd),

                        // ── Period selector ────────────────────────────────
                        _PeriodSelector(
                          selected: period,
                          onChanged: (p) {
                            ref.read(analyticsPeriodProvider.notifier).state =
                                p;
                          },
                        ),
                        const SizedBox(height: AppSpacing.stackLg),

                        // ── Efficiency trend chart ─────────────────────────
                        _EfficiencyTrendCard(
                          trips: stats.trips,
                          peakKmPerLiter: stats.peakKmPerLiter,
                          fuelType: stats.fuelType,
                        ),
                        const SizedBox(height: AppSpacing.gutter),

                        // ── Insight row ────────────────────────────────────
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

                        // ── Monthly spending chart ─────────────────────────
                        _MonthlySpendingCard(
                          monthly: stats.monthlySpending,
                          currency: currency,
                        ),
                        const SizedBox(height: AppSpacing.gutter),

                        // ── Pie + metrics ──────────────────────────────────
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

                        // ── Vehicle profiles ───────────────────────────────
                        if (stats.vehicleProfiles.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.stackLg),
                          const SectionHeader(title: 'Vehicle Profiles'),
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

// ── Period selector ────────────────────────────────────────────────────────────

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

// ── Card shells ────────────────────────────────────────────────────────────────

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

// ── Efficiency trend chart ─────────────────────────────────────────────────────

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Need 2+ refuels for trends',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      minY: _minY(trips),
                      maxY: _maxY(trips),
                      gridData: FuelChartStyle.horizontalGrid(cs),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.min || value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toStringAsFixed(1),
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 9,
                                ),
                                textAlign: TextAlign.right,
                              );
                            },
                          ),
                        ),
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
    final min =
        trips.map((t) => t.kmPerLiter).reduce((a, b) => a < b ? a : b);
    return (min * 0.85).floorToDouble();
  }

  double _maxY(List<TripEfficiency> trips) {
    final max =
        trips.map((t) => t.kmPerLiter).reduce((a, b) => a > b ? a : b);
    return (max * 1.15).ceilToDouble();
  }
}

// ── Insight cards ──────────────────────────────────────────────────────────────

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
        ? '${improved ? '+' : ''}${changePercent!.toStringAsFixed(0)}%'
        : FuelTypeMetrics.formatEfficiency(avgKmPerLiter, fuelType);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -6,
            child: Icon(
              improved ? Icons.trending_up : Icons.trending_down,
              size: 56,
              color: trendColor.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.bolt,
                  color: pal.efficiency,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Efficiency',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                headline,
                style: tt.titleSmall?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                changePercent != null
                    ? 'vs. previous period'
                    : 'avg efficiency',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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
    final pal = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pal.spend.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payments, color: pal.spend, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Cost / km',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            costPerKm != null ? costPerKm!.toStringAsFixed(3) : '—',
            style: tt.titleSmall?.copyWith(
              color: pal.spend,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            currency,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Monthly spending chart ─────────────────────────────────────────────────────

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
          ? SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'No spending data yet',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          : SizedBox(
              height: 220,
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toStringAsFixed(0),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
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
                                fontSize: 9,
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

// ── Pie chart ──────────────────────────────────────────────────────────────────

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
    final cs = context.cs;
    final colors = _pieColors(context);
    final qtyUnit = FuelTypeMetrics.quantityUnit(fuelType);

    return _SectionCard(
      title: 'Vehicle Fuel Share',
      child: vehicleShares.isEmpty
          ? SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'No fuel data',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
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
                    style: tt.labelMedium,
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
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            share.vehicle.displayName,
                            style: tt.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${share.percent.toStringAsFixed(0)}%',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
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

// ── Efficiency metrics ─────────────────────────────────────────────────────────

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
            value: '$currency ${totalSpent.toStringAsFixed(2)}',
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.tt.labelMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: context.tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vehicle profile card ───────────────────────────────────────────────────────

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pal.fuel.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.directions_car_filled_outlined,
              color: pal.fuel,
              size: 22,
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
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (profile.avgKmPerLiter != null)
                  Text(
                    'Avg. ${FuelTypeMetrics.formatEfficiency(profile.avgKmPerLiter, vehicle.fuelType)}',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: pal.efficiency,
                    ),
                  )
                else
                  Text(
                    'Need more refuels',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
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
