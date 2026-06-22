import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard_stats.dart';
import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../services/fuel_calculations.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _selectVehicle(
    WidgetRef ref,
    BuildContext context,
    Vehicle vehicle,
  ) async {
    final settings = await ref.read(settingsProvider.future);
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(selectedVehicleId: vehicle.id),
        );
    ref.invalidate(dashboardProvider);
  }

  void _showVehiclePicker(
    BuildContext context,
    WidgetRef ref,
    DashboardViewModel data,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'Select vehicle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...data.allVehicles.map(
                (v) => ListTile(
                  leading: const Icon(Icons.directions_car_outlined),
                  title: Text(v.displayName),
                  subtitle: Text(v.fuelType.label),
                  onTap: () {
                    Navigator.pop(context);
                    _selectVehicle(ref, context, v);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                child: _DashboardHeader(
                  vehicleName: vehicle.displayName,
                  onVehicleTap: data.allVehicles.length > 1
                      ? () => _showVehiclePicker(context, ref, data)
                      : null,
                  onSettingsTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming in Step 8')),
                    );
                  },
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
                    _HeroCards(stats: stats),
                    const SizedBox(height: AppSpacing.stackLg),
                    _QuickOverview(
                      stats: stats,
                      currency: currency,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    if (stats.lastRefuel != null)
                      _LastRefuelCard(
                        entry: stats.lastRefuel!,
                        currency: currency,
                      ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _MonthlySpendChart(
                      monthly: stats.monthlySpending,
                      currency: currency,
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    _EfficiencyTrendChart(trips: stats.efficiencyTrend),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.vehicleName,
    this.onVehicleTap,
    required this.onSettingsTap,
  });

  final String vehicleName;
  final VoidCallback? onVehicleTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.stackMd,
        AppSpacing.marginMobile,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onVehicleTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  vehicleName,
                                  style: theme.textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onVehicleTap != null)
                                const Icon(Icons.expand_more, size: 18),
                            ],
                          ),
                          Text(
                            'FuelTrack Pro',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

class _HeroCards extends StatelessWidget {
  const _HeroCards({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final odometer = stats.currentOdometer;
    final avg = stats.avgKmPerLiter;
    final trend = stats.efficiencyTrendPercent;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryContainer, AppColors.primaryFixedDim],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT ODOMETER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  odometer != null
                      ? NumberFormat('#,###').format(odometer.round())
                      : '—',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'km',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.secondaryContainer],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVG EFFICIENCY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      avg != null ? avg.toStringAsFixed(1) : '—',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'km/L',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                if (trend != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 14,
                          color: Colors.white,
                        ),
                        Text(
                          '${trend.abs().toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
  const _QuickOverview({required this.stats, required this.currency});

  final DashboardStats stats;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total Spent',
                value: '$currency ${stats.totalSpent30Days.toStringAsFixed(3)}',
                subtitle: 'Last 30 days',
                valueColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: _StatTile(
                label: 'Total Liters',
                value: '${stats.totalLiters30Days.toStringAsFixed(0)} L',
                subtitle: '${stats.fillUps30Days} fill-ups',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.tertiaryContainer,
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost per km',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      stats.costPerKm30Days != null
                          ? '${stats.costPerKm30Days!.toStringAsFixed(3)} $currency'
                          : '—',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
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
    final theme = Theme.of(context);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(color: valueColor),
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LastRefuelCard extends StatelessWidget {
  const _LastRefuelCard({required this.entry, required this.currency});

  final RefuelEntry entry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysAgo = DateTime.now().difference(entry.refuelDate).inDays;
    final agoLabel = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
            ? 'Yesterday'
            : '$daysAgo days ago';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Last Refuel',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('Details')),
          ],
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: const Icon(
                  Icons.local_gas_station,
                  size: 40,
                  color: AppColors.secondary,
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
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              agoLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.outline,
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${entry.quantity.toStringAsFixed(0)}L • ${entry.pricePerLiter?.toStringAsFixed(3) ?? '—'}/L',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
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
    if (monthly.isEmpty) {
      return _ChartCard(
        title: 'Monthly Spend',
        icon: Icons.bar_chart,
        child: const SizedBox(
          height: 120,
          child: Center(child: Text('No spending data yet')),
        ),
      );
    }

    final maxY = monthly.map((m) => m.amount).reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Monthly Spend',
      icon: Icons.bar_chart,
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.2,
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
                    final isLast = index == monthly.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        monthly[index].label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isLast
                              ? AppColors.onSurface
                              : AppColors.outline,
                          fontWeight:
                              isLast ? FontWeight.bold : FontWeight.normal,
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
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      color: i == monthly.length - 1
                          ? AppColors.primaryContainer
                          : AppColors.secondaryContainer,
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
  const _EfficiencyTrendChart({required this.trips});

  final List<TripEfficiency> trips;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _ChartCard(
        title: 'Efficiency Trend',
        icon: Icons.show_chart,
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

    return _ChartCard(
      title: 'Efficiency Trend',
      icon: Icons.show_chart,
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            minY: (minY * 0.9).floorToDouble(),
            maxY: (maxY * 1.1).ceilToDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
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
                spots: spots,
                isCurved: true,
                color: AppColors.surfaceTint,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
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
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Icon(icon, size: 18, color: AppColors.outline),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          child,
        ],
      ),
    );
  }
}
