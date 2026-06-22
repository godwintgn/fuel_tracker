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
import '../../theme/theme_x.dart';
import '../refuel/add_refuel_screen.dart';
import '../settings/settings_screen.dart';
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
                  style: context.tt.titleMedium,
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
              const SizedBox(height: AppSpacing.stackMd),
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
                  onSettingsTap: () => SettingsScreen.open(context),
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
                        onDetails: () => AddRefuelScreen.openForEdit(
                          context,
                          entry: stats.lastRefuel!,
                        ),
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
    final cs = context.cs;
    final tt = context.tt;

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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Icon(Icons.directions_car, color: cs.primary),
                    ),
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
                                  style: tt.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onVehicleTap != null)
                                Icon(
                                  Icons.expand_more,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                            ],
                          ),
                          Text(
                            'FuelTrack Pro',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
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
    final tt = context.tt;
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT ODOMETER',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.onPrimaryFixed.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  odometer != null
                      ? NumberFormat('#,###').format(odometer.round())
                      : '—',
                  style: tt.headlineSmall?.copyWith(
                    color: AppColors.onPrimaryFixed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'km',
                  style: tt.titleMedium?.copyWith(
                    color: AppColors.onPrimaryFixed.withValues(alpha: 0.75),
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVG EFFICIENCY',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      avg != null ? avg.toStringAsFixed(1) : '—',
                      style: tt.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'km/L',
                      style: tt.titleMedium?.copyWith(
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
                          style: tt.labelSmall?.copyWith(
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
    final cs = context.cs;
    final tt = context.tt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: tt.titleMedium?.copyWith(
            color: cs.onSurfaceVariant,
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
                valueColor: cs.primary,
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
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.tertiaryContainer,
                child: Icon(
                  Icons.payments_outlined,
                  color: cs.onTertiaryContainer,
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
                      style: tt.titleMedium,
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

    return Container(
      height: 120,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: tt.titleLarge?.copyWith(color: valueColor),
              ),
              Text(
                subtitle,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Last Refuel',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            TextButton(onPressed: onDetails, child: const Text('Details')),
          ],
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onDetails,
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
                                color: cs.primary,
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
                          color: isLast ? cs.onSurface : cs.onSurfaceVariant,
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
                          ? cs.primary
                          : cs.primary.withValues(alpha: 0.35),
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
    final cs = context.cs;

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
                spots: spots,
                isCurved: true,
                color: cs.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: cs.primary.withValues(alpha: 0.10),
                ),
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
    final cs = context.cs;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: context.tt.titleMedium),
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          child,
        ],
      ),
    );
  }
}
