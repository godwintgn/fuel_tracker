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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currencySymbol ?? 'OMR';

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        AppSpacing.stackSm,
                        AppSpacing.marginMobile,
                        0,
                      ),
                      child: Text(
                        'Dashboard',
                        style: context.tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ActiveVehicleBar(
                      vehicles: data.allVehicles,
                      embedded: true,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.stackMd,
                  AppSpacing.marginMobile,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroCards(stats: stats, fuelType: vehicle.fuelType),
                    const SizedBox(height: AppSpacing.stackLg),
                    _QuickOverview(
                      stats: stats,
                      currency: currency,
                      fuelType: vehicle.fuelType,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    if (stats.lastRefuel != null)
                      _LastRefuelCard(
                        entry: stats.lastRefuel!,
                        currency: currency,
                        onDetails: () => RefuelDetailScreen.open(
                          context,
                          entry: stats.lastRefuel!,
                          vehicle: vehicle,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.stackLg),
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

class _HeroCards extends StatelessWidget {
  const _HeroCards({required this.stats, required this.fuelType});

  final DashboardStats stats;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final odometer = stats.currentOdometer;
    final avg = stats.avgKmPerLiter;
    final trend = stats.efficiencyTrendPercent;
    final trendUp = (trend ?? 0) >= 0;
    final trendColor = trendUp ? pal.gain : pal.loss;

    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current odometer',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  odometer != null
                      ? NumberFormat('#,###').format(odometer.round())
                      : '—',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'km',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avg efficiency',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  FuelTypeMetrics.formatEfficiency(avg, fuelType),
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: pal.efficiency,
                  ),
                ),
                if (trend != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: trendColor,
                        ),
                        Text(
                          '${trend.abs().toStringAsFixed(0)}%',
                          style: tt.labelSmall?.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
                value: '$currency ${stats.totalSpent30Days.toStringAsFixed(3)}',
                subtitle: 'Last 30 days',
                valueColor: context.palette.spend,
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: _StatTile(
                label: 'Total ${FuelTypeMetrics.quantityUnit(fuelType)}',
                value:
                    '${stats.totalLiters30Days.toStringAsFixed(0)} ${FuelTypeMetrics.quantityUnit(fuelType)}',
                subtitle: '${stats.fillUps30Days} fill-ups',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        AppCard(
          onTap: null,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.palette.fuel.withValues(alpha: 0.15),
                child: Icon(
                  Icons.payments_outlined,
                  color: context.palette.fuel,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost per km',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      stats.costPerKm30Days != null
                          ? '${stats.costPerKm30Days!.toStringAsFixed(3)} $currency'
                          : '—',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
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
    required this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: tt.titleMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
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

class _LastRefuelCard extends StatelessWidget {
  const _LastRefuelCard({
    required this.entry,
    required this.currency,
    required this.onDetails,
  });

  final RefuelEntry entry;
  final String currency;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Last Refuel',
          actionLabel: 'Details',
          onActionTap: onDetails,
        ),
        AppCard(
          onTap: onDetails,
          padding: EdgeInsets.zero,
          child: Row(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: Icon(
                    Icons.local_gas_station,
                    size: 40,
                    color: cs.secondary,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.stationName ?? 'Fuel stop',
                                style: tt.titleMedium,
                              ),
                              Text(
                                agoLabel,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$currency ${entry.totalPrice.toStringAsFixed(3)}',
                              style: tt.titleMedium?.copyWith(
                                color: context.palette.spend,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${entry.quantity.toStringAsFixed(0)}L • ${entry.pricePerLiter?.toStringAsFixed(3) ?? '—'}/L',
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

class _MonthlySpendChart extends StatelessWidget {
  const _MonthlySpendChart({
    required this.monthly,
    required this.currency,
  });

  final List<MonthlySpend> monthly;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;

    if (monthly.isEmpty) {
      return _ChartCard(
        title: 'Monthly Spend',
        subtitle: 'Fuel spending by month',
        child: const SizedBox(
          height: 120,
          child: Center(child: Text('No spending data yet')),
        ),
      );
    }

    final maxY = monthly.map((m) => m.amount).reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Monthly Spend',
      subtitle: 'Fuel spending by month',
      child: SizedBox(
        height: 168,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            maxY: maxY * 1.15,
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
                        monthly[index].label,
                        style: tt.labelSmall?.copyWith(
                          color: isLast ? cs.onSurface : cs.onSurfaceVariant,
                          fontWeight:
                              isLast ? FontWeight.w700 : FontWeight.normal,
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
    final pal = context.palette;
    final unit = FuelTypeMetrics.efficiencyUnit(fuelType);

    if (trips.isEmpty) {
      return _ChartCard(
        title: 'Efficiency Trend',
        subtitle: '$unit over recent fill-ups',
        child: const SizedBox(
          height: 120,
          child: Center(child: Text('Need 2+ refuels for trends')),
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
        height: 168,
        child: LineChart(
          LineChartData(
            minY: (minY * 0.9).floorToDouble(),
            maxY: (maxY * 1.1).ceilToDouble(),
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
