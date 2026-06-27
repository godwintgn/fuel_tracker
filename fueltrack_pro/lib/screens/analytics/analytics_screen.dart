import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/fuel_type_metrics.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/fuel_chart_style.dart';
import '../../theme/theme_x.dart';
import '../../utils/vehicle_color.dart';
import '../../widgets/common/active_vehicle_bar.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/summary_header_card.dart';
import '../../widgets/common/summary_stat.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../refuel/add_refuel_screen.dart';
import '../refuel/refuel_detail_screen.dart';

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

    final vehiclesById = {
      for (final v in vehicles)
        if (v.id != null) v.id!: v,
    };

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
                  _PeriodSelectorBar(
                    selected: period,
                    onChanged: (p) =>
                        ref.read(analyticsPeriodProvider.notifier).state = p,
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

            final hasMultiVehicle = stats.vehicleEfficiencyData.length > 1;

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
                        // ── Header card ──────────────────────────────────────
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
                            if (stats.nextRefuelPredictionKm != null)
                              SummaryStat(
                                label: 'Avg/fill',
                                value:
                                    '~${stats.nextRefuelPredictionKm!.toStringAsFixed(0)} km',
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.stackMd),

                        // ── Period selector ──────────────────────────────────
                        _PeriodSelectorBar(
                          selected: period,
                          onChanged: (p) =>
                              ref.read(analyticsPeriodProvider.notifier).state =
                                  p,
                        ),
                        const SizedBox(height: AppSpacing.stackLg),

                        // ── Best / Worst fill ────────────────────────────────
                        if (stats.bestFill != null || stats.worstFill != null) ...[
                          _BestWorstFillRow(
                            bestFill: stats.bestFill,
                            worstFill: stats.worstFill,
                            vehiclesById: vehiclesById,
                            currency: currency,
                          ),
                          const SizedBox(height: AppSpacing.gutter),
                        ],

                        // ── Efficiency trend chart ───────────────────────────
                        _EfficiencyTrendCard(
                          stats: stats,
                          vehiclesById: vehiclesById,
                          hasMultiVehicle: hasMultiVehicle,
                        ),
                        const SizedBox(height: AppSpacing.gutter),

                        // ── Fill cost trend chart ────────────────────────────
                        if (stats.fillCostTrend.length >= 2) ...[
                          _FillCostTrendCard(
                            trend: stats.fillCostTrend,
                            currency: currency,
                            vehiclesById: vehiclesById,
                          ),
                          const SizedBox(height: AppSpacing.gutter),
                        ],

                        // ── Insight row ──────────────────────────────────────
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

                        // ── Monthly spending chart ───────────────────────────
                        _MonthlySpendingCard(
                          monthly: stats.monthlySpending,
                          currency: currency,
                        ),

                        // ── Station comparison ───────────────────────────────
                        if (stats.stationStats.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.gutter),
                          _StationComparisonCard(
                            stations: stats.stationStats,
                            currency: currency,
                          ),
                        ],

                        const SizedBox(height: AppSpacing.gutter),

                        // ── Pie + metrics ────────────────────────────────────
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

                        // ── Vehicle profiles ─────────────────────────────────
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

// ── Period selector bar ────────────────────────────────────────────────────────

class _PeriodSelectorBar extends StatelessWidget {
  const _PeriodSelectorBar({
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

// ── Card shell ─────────────────────────────────────────────────────────────────

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

// ── Best / Worst fill row ──────────────────────────────────────────────────────

class _BestWorstFillRow extends StatelessWidget {
  const _BestWorstFillRow({
    required this.bestFill,
    required this.worstFill,
    required this.vehiclesById,
    required this.currency,
  });

  final RefuelEntry? bestFill;
  final RefuelEntry? worstFill;
  final Map<int, Vehicle> vehiclesById;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (bestFill != null)
          Expanded(
            child: _FillHighlightCard(
              entry: bestFill!,
              vehicle: vehiclesById[bestFill!.vehicleId],
              label: 'Best Fill',
              icon: Icons.thumb_up_outlined,
              isGood: true,
              currency: currency,
            ),
          ),
        if (bestFill != null && worstFill != null)
          const SizedBox(width: AppSpacing.gutter),
        if (worstFill != null)
          Expanded(
            child: _FillHighlightCard(
              entry: worstFill!,
              vehicle: vehiclesById[worstFill!.vehicleId],
              label: 'Costly Fill',
              icon: Icons.thumb_down_outlined,
              isGood: false,
              currency: currency,
            ),
          ),
      ],
    );
  }
}

class _FillHighlightCard extends StatelessWidget {
  const _FillHighlightCard({
    required this.entry,
    required this.vehicle,
    required this.label,
    required this.icon,
    required this.isGood,
    required this.currency,
  });

  final RefuelEntry entry;
  final Vehicle? vehicle;
  final String label;
  final IconData icon;
  final bool isGood;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final color = isGood ? pal.gain : pal.loss;
    final dateStr = DateFormat('d MMM').format(entry.refuelDate);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => RefuelDetailScreen.open(
        context,
        entry: entry,
        vehicle: vehicle,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              entry.pricePerLiter != null
                  ? '$currency ${entry.pricePerLiter!.toStringAsFixed(3)}/L'
                  : '$currency ${entry.totalPrice.toStringAsFixed(2)}',
              style: tt.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (vehicle != null)
              Text(
                vehicle!.displayName,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Efficiency trend chart ─────────────────────────────────────────────────────

class _EfficiencyTrendCard extends StatelessWidget {
  const _EfficiencyTrendCard({
    required this.stats,
    required this.vehiclesById,
    required this.hasMultiVehicle,
  });

  final AnalyticsStats stats;
  final Map<int, Vehicle> vehiclesById;
  final bool hasMultiVehicle;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final fuelType = stats.fuelType;
    final unit = FuelTypeMetrics.efficiencyUnit(fuelType);
    final vehicleData = stats.vehicleEfficiencyData;

    // Build line series — one per vehicle if multi, else single fallback
    final seriesList = _buildSeries(context, vehicleData, pal.efficiency);

    return _SectionCard(
      title: hasMultiVehicle ? 'Efficiency — All Vehicles' : 'Consumption Trends',
      subtitle: 'Historical $unit performance${hasMultiVehicle ? ' (tap point to view)' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Unit badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pal.efficiency.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unit,
                  style: tt.labelSmall?.copyWith(
                    color: pal.efficiency,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Peak badge (single vehicle)
              if (!hasMultiVehicle && stats.peakKmPerLiter != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pal.efficiency,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Peak: ${stats.peakKmPerLiter!.toStringAsFixed(1)} $unit',
                    style: tt.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),

          if (seriesList.isEmpty)
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
              child: LineChart(
                LineChartData(
                  minY: _minY(vehicleData),
                  maxY: _maxY(vehicleData),
                  gridData: FuelChartStyle.horizontalGrid(cs),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final spots = response?.lineBarSpots;
                      if (spots == null || spots.isEmpty) return;
                      final spot = spots.first;
                      final barIdx = spot.barIndex;
                      final tripIdx = spot.spotIndex;
                      if (barIdx >= vehicleData.length) return;
                      final vd = vehicleData[barIdx];
                      if (tripIdx >= vd.trips.length) return;
                      final trip = vd.trips[tripIdx];
                      // Find matching entry by vehicle + date
                      final entry = stats.entries.cast<RefuelEntry?>().firstWhere(
                        (e) =>
                            e!.vehicleId == vd.vehicle.id &&
                            e.refuelDate.isAtSameMomentAs(trip.refuelDate),
                        orElse: () => null,
                      );
                      if (entry != null && context.mounted) {
                        RefuelDetailScreen.open(
                          context,
                          entry: entry,
                          vehicle: vd.vehicle,
                        );
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final barIdx = s.barIndex;
                        final vd = barIdx < vehicleData.length
                            ? vehicleData[barIdx]
                            : null;
                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(1)} $unit',
                          tt.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ) ??
                              const TextStyle(color: Colors.white),
                          children: vd != null && hasMultiVehicle
                              ? [
                                  TextSpan(
                                    text: '\n${vd.vehicle.displayName}',
                                    style: tt.labelSmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ]
                              : [],
                        );
                      }).toList(),
                    ),
                  ),
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
                  lineBarsData: seriesList,
                ),
              ),
            ),

          // Multi-vehicle legend
          if (hasMultiVehicle && vehicleData.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: vehicleData.map((vd) {
                final color = vd.vehicle.id != null
                    ? vehicleAccentColor(vd.vehicle.id!, cs)
                    : pal.efficiency;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vd.vehicle.displayName,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<LineChartBarData> _buildSeries(
    BuildContext context,
    List<VehicleEfficiencyData> vehicleData,
    Color defaultColor,
  ) {
    final cs = context.cs;
    if (vehicleData.isEmpty) return [];

    if (vehicleData.length == 1) {
      final trips = vehicleData.first.trips;
      if (trips.isEmpty) return [];
      return [
        FuelChartStyle.primarySeries(
          spots: [
            for (var i = 0; i < trips.length; i++)
              FlSpot(i.toDouble(), trips[i].kmPerLiter),
          ],
          color: defaultColor,
          barWidth: FuelChartStyle.barWidthFull,
        ),
      ];
    }

    // Multi-vehicle — one line per vehicle
    return vehicleData.map((vd) {
      final color = vd.vehicle.id != null
          ? vehicleAccentColor(vd.vehicle.id!, cs)
          : defaultColor;
      return FuelChartStyle.primarySeries(
        spots: [
          for (var i = 0; i < vd.trips.length; i++)
            FlSpot(i.toDouble(), vd.trips[i].kmPerLiter),
        ],
        color: color,
        barWidth: FuelChartStyle.barWidthFull,
      );
    }).toList();
  }

  double _minY(List<VehicleEfficiencyData> vehicleData) {
    final all = vehicleData.expand((vd) => vd.trips.map((t) => t.kmPerLiter));
    if (all.isEmpty) return 0;
    final min = all.reduce((a, b) => a < b ? a : b);
    return (min * 0.85).floorToDouble();
  }

  double _maxY(List<VehicleEfficiencyData> vehicleData) {
    final all = vehicleData.expand((vd) => vd.trips.map((t) => t.kmPerLiter));
    if (all.isEmpty) return 10;
    final max = all.reduce((a, b) => a > b ? a : b);
    return (max * 1.15).ceilToDouble();
  }
}

// ── Fill cost trend chart ──────────────────────────────────────────────────────

class _FillCostTrendCard extends StatefulWidget {
  const _FillCostTrendCard({
    required this.trend,
    required this.currency,
    required this.vehiclesById,
  });

  final List<FillCostPoint> trend;
  final String currency;
  final Map<int, Vehicle> vehiclesById;

  @override
  State<_FillCostTrendCard> createState() => _FillCostTrendCardState();
}

class _FillCostTrendCardState extends State<_FillCostTrendCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final trend = widget.trend;
    final maxY = trend
            .map((p) => p.totalPrice)
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return _SectionCard(
      title: 'Cost per Fill-up',
      subtitle: 'Tap a bar to view that entry',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.start,
            maxY: maxY,
            groupsSpace: 4,
            gridData: FuelChartStyle.horizontalGrid(cs),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchCallback: (event, response) {
                if (event is FlTapUpEvent) {
                  final idx = response?.spot?.touchedBarGroupIndex;
                  if (idx != null && idx >= 0 && idx < trend.length) {
                    final point = trend[idx];
                    final vehicle =
                        widget.vehiclesById[point.entry.vehicleId];
                    RefuelDetailScreen.open(
                      context,
                      entry: point.entry,
                      vehicle: vehicle,
                    );
                  }
                }
                if (event is FlPointerHoverEvent || event is FlTapDownEvent) {
                  setState(() {
                    _touchedIndex =
                        response?.spot?.touchedBarGroupIndex;
                  });
                } else {
                  setState(() => _touchedIndex = null);
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIdx, rod, rodIdx) {
                  final p = trend[groupIdx];
                  final dateStr = DateFormat('d MMM').format(p.date);
                  return BarTooltipItem(
                    '$dateStr\n${widget.currency} ${p.totalPrice.toStringAsFixed(2)}',
                    tt.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: const AxisTitles(),
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
            ),
            barGroups: [
              for (var i = 0; i < trend.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: trend[i].totalPrice,
                      width: trend.length > 20 ? 4 : 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                      color: _touchedIndex == i
                          ? pal.spend
                          : pal.spend.withValues(alpha: 0.45),
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
                child: Icon(Icons.bolt, color: pal.efficiency, size: 22),
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
      subtitle: '$currency — fuel cost by month',
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
                        reservedSize: 44,
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

// ── Station comparison ─────────────────────────────────────────────────────────

class _StationComparisonCard extends StatelessWidget {
  const _StationComparisonCard({
    required this.stations,
    required this.currency,
  });

  final List<StationStat> stations;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pal = context.palette;
    final displayed = stations.take(6).toList();

    // Find max avgPricePerLiter for bar scaling
    final maxPrice = displayed
        .where((s) => s.avgPricePerLiter != null)
        .map((s) => s.avgPricePerLiter!)
        .fold<double>(0, (a, b) => b > a ? b : a);

    return _SectionCard(
      title: 'Station Comparison',
      subtitle: 'Avg price/L · cheapest first',
      child: Column(
        children: displayed.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final fraction = (maxPrice > 0 && s.avgPricePerLiter != null)
              ? s.avgPricePerLiter! / maxPrice
              : 0.0;
          final isCheapest = i == 0 && s.avgPricePerLiter != null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Rank badge
                SizedBox(
                  width: 20,
                  child: Text(
                    '${i + 1}',
                    style: tt.labelSmall?.copyWith(
                      color: isCheapest ? pal.gain : cs.onSurfaceVariant,
                      fontWeight:
                          isCheapest ? FontWeight.w700 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: tt.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isCheapest ? cs.onSurface : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (s.avgPricePerLiter != null)
                            Text(
                              '$currency ${s.avgPricePerLiter!.toStringAsFixed(3)}/L',
                              style: tt.labelSmall?.copyWith(
                                color: isCheapest ? pal.gain : cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            Text(
                              '${s.visitCount} fill${s.visitCount != 1 ? 's' : ''}',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 3,
                                backgroundColor:
                                    cs.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCheapest
                                      ? pal.gain
                                      : pal.spend.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${s.visitCount} visit${s.visitCount != 1 ? 's' : ''}',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
    final vehicle = profile.vehicle;
    final accentColor = vehicle.id != null
        ? vehicleAccentColor(vehicle.id!, cs)
        : context.palette.fuel;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.directions_car_filled_outlined,
              color: accentColor,
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
                      color: context.palette.efficiency,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${profile.totalLiters.toStringAsFixed(0)} L',
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'used',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
