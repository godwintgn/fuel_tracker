import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/refuel_entry.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/fuel_calculations.dart';
import '../../services/fuel_type_metrics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/fuel_chart_style.dart';
import '../../theme/theme_x.dart';
import '../refuel/refuel_detail_screen.dart';
import '../../widgets/common/active_vehicle_bar.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/summary_header_card.dart';
import '../../widgets/common/summary_stat.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currencySymbol ?? 'OMR';

    return dashboardAsync.when(
      loading: () => const _DashboardSkeleton(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.vehicle == null) {
          return const EmptyState(
            icon: Icons.dashboard_outlined,
            title: 'No vehicle selected',
            message: 'Add a vehicle to see your fuel dashboard.',
          );
        }

        final stats = data.stats;
        final vehicle = data.vehicle!;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
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
                    // ── Header card ──────────────────────────────────────────
                    SummaryHeaderCard(
                      icon: Icons.speed_outlined,
                      title: 'Dashboard',
                      headlineValue: stats.currentOdometer != null
                          ? NumberFormat('#,###')
                              .format(stats.currentOdometer!.round())
                          : '—',
                      headlineUnit: 'km',
                      subtitle: 'Current odometer',
                      trailing: SizedBox(
                        width: 200,
                        child: ActiveVehicleBar(
                          vehicles: data.allVehicles,
                          embedded: true,
                        ),
                      ),
                      stats: [
                        SummaryStat(
                          label: 'Avg',
                          value: FuelTypeMetrics.formatEfficiency(
                            stats.avgKmPerLiter,
                            vehicle.fuelType,
                          ),
                          color: context.palette.efficiency,
                        ),
                        SummaryStat(
                          label: '30d',
                          value:
                              '$currency ${stats.totalSpent30Days.toStringAsFixed(2)}',
                          color: context.palette.spend,
                        ),
                        if (stats.efficiencyTrendPercent != null)
                          SummaryStat(
                            label: 'Trend',
                            value:
                                '${(stats.efficiencyTrendPercent! >= 0 ? '+' : '')}${stats.efficiencyTrendPercent!.toStringAsFixed(0)}%',
                            color: (stats.efficiencyTrendPercent! >= 0)
                                ? context.palette.gain
                                : context.palette.loss,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Quick Overview ───────────────────────────────────────
                    _QuickOverview(
                      stats: stats,
                      currency: currency,
                      fuelType: vehicle.fuelType,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Last Refuel ──────────────────────────────────────────
                    if (stats.lastRefuel != null)
                      _LastRefuelCard(
                        entry: stats.lastRefuel!,
                        currency: currency,
                        fuelType: vehicle.fuelType,
                        onDetails: () => RefuelDetailScreen.open(
                          context,
                          entry: stats.lastRefuel!,
                          vehicle: vehicle,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Charts ───────────────────────────────────────────────
                    _MonthlySpendChart(
                      monthly: stats.monthlySpending,
                      currency: currency,
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    _EfficiencyTrendChart(
                      trips: stats.efficiencyTrend,
                      fuelType: vehicle.fuelType,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Quick Overview ─────────────────────────────────────────────────────────────

class _QuickOverview extends StatelessWidget {
  const _QuickOverview({
    required this.stats,
    required this.currency,
    required this.fuelType,
  });

  final DashboardStats stats;
  final String currency;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Quick Overview',
          subtitle: 'Last 30 days',
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total Spent',
                value: '$currency ${stats.totalSpent30Days.toStringAsFixed(2)}',
                sub: 'Last 30 days',
                valueColor: context.palette.spend,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Total ${FuelTypeMetrics.quantityUnit(fuelType)}',
                value:
                    '${stats.totalLiters30Days.toStringAsFixed(0)} ${FuelTypeMetrics.quantityUnit(fuelType)}',
                sub: '${stats.fillUps30Days} fill-ups',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 20,
                color: context.palette.fuel,
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Text(
                  'Cost per km',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              Text(
                stats.costPerKm30Days != null
                    ? '${stats.costPerKm30Days!.toStringAsFixed(3)} $currency'
                    : '—',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });

  final String label;
  final String value;
  final String sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            sub,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Last Refuel ────────────────────────────────────────────────────────────────

class _LastRefuelCard extends StatelessWidget {
  const _LastRefuelCard({
    required this.entry,
    required this.currency,
    required this.fuelType,
    required this.onDetails,
  });

  final RefuelEntry entry;
  final String currency;
  final FuelType fuelType;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final daysAgo = DateTime.now().difference(entry.refuelDate).inDays;
    final agoLabel = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
            ? 'Yesterday'
            : '$daysAgo days ago';
    final qtyUnit = FuelTypeMetrics.quantityUnit(fuelType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Last Refuel',
          actionLabel: 'Details',
          onActionTap: onDetails,
        ),
        const SizedBox(height: AppSpacing.stackSm),
        AppCard(
          onTap: onDetails,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: Icon(
                  Icons.local_gas_station,
                  size: 24,
                  color: cs.secondary,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.stationName ?? 'Fuel stop',
                              style: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              agoLabel,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$currency ${entry.totalPrice.toStringAsFixed(2)}',
                            style: tt.titleSmall?.copyWith(
                              color: context.palette.spend,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${entry.quantity.toStringAsFixed(0)} $qtyUnit',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Charts ─────────────────────────────────────────────────────────────────────

class _MonthlySpendChart extends StatelessWidget {
  const _MonthlySpendChart({required this.monthly, required this.currency});

  final List<MonthlySpend> monthly;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;

    if (monthly.isEmpty) {
      return const _ChartCard(
        title: 'Monthly Spend',
        subtitle: 'Fuel spending by month',
        child: _ChartEmpty(
          icon: Icons.bar_chart_outlined,
          message: 'Log a refuel to see monthly spending.',
        ),
      );
    }

    final maxY = monthly.map((m) => m.amount).reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Monthly Spend',
      subtitle: 'Fuel spending by month',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            maxY: maxY * 1.15,
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
                        monthly[index].label,
                        style: tt.labelSmall?.copyWith(
                          color:
                              isLast ? cs.onSurface : cs.onSurfaceVariant,
                          fontWeight:
                              isLast ? FontWeight.w700 : FontWeight.normal,
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

class _EfficiencyTrendChart extends StatelessWidget {
  const _EfficiencyTrendChart({required this.trips, required this.fuelType});

  final List<TripEfficiency> trips;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final unit = FuelTypeMetrics.efficiencyUnit(fuelType);

    if (trips.isEmpty) {
      return _ChartCard(
        title: 'Efficiency Trend',
        subtitle: '$unit over recent fill-ups',
        child: const _ChartEmpty(
          icon: Icons.show_chart_outlined,
          message: 'Log 2+ refuels to chart your efficiency trend.',
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < trips.length; i++)
        FlSpot(i.toDouble(), trips[i].kmPerLiter),
    ];

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final lineColor = pal.efficiency;

    return _ChartCard(
      title: 'Efficiency Trend',
      subtitle: '$unit over recent fill-ups',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: (minY * 0.9).floorToDouble(),
            maxY: (maxY * 1.1).ceilToDouble(),
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
              bottomTitles: const AxisTitles(),
            ),
            lineBarsData: [
              FuelChartStyle.primarySeries(
                spots: spots,
                color: lineColor,
                barWidth: FuelChartStyle.barWidthFull,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.stackMd),
          child,
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: cs.onSurfaceVariant),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.stackMd,
        AppSpacing.marginMobile,
        120,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SkeletonBox(height: 108),
        SizedBox(height: AppSpacing.stackLg),
        _SkeletonBox(height: 20, width: 140),
        SizedBox(height: AppSpacing.stackMd),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 72)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 72)),
          ],
        ),
        SizedBox(height: 10),
        _SkeletonBox(height: 48),
        SizedBox(height: AppSpacing.stackLg),
        _SkeletonBox(height: 52),
        SizedBox(height: AppSpacing.stackLg),
        _SkeletonBox(height: 240),
        SizedBox(height: AppSpacing.gutter),
        _SkeletonBox(height: 240),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
  }
}
