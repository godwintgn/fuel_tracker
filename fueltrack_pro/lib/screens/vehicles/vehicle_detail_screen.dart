import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/selected_vehicle_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/fuel_calculations.dart';
import '../../services/fuel_type_metrics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/detail_row.dart';
import '../../widgets/vehicles/vehicle_photo_view.dart';
import '../refuel/add_refuel_screen.dart';
import '../refuel/refuel_detail_screen.dart';
import 'add_edit_vehicle_screen.dart';

/// Read-only vehicle profile with quick stats and recent activity.
class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  static Future<void> open(BuildContext context, {required Vehicle vehicle}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.cs;
    final tt = context.tt;
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];
    final resolved = vehicles.cast<Vehicle?>().firstWhere(
          (v) => v?.id == vehicle.id,
          orElse: () => vehicle,
        )!;

    final settings = ref.watch(settingsProvider).valueOrNull;
    final currency = settings?.currencySymbol ?? r'$';
    final distanceUnit = settings?.distanceUnit.abbreviation ?? 'km';

    final refuelsAsync = resolved.id != null
        ? ref.watch(vehicleRefuelsProvider(resolved.id!))
        : const AsyncValue<List<RefuelEntry>>.data([]);
    final refuels = refuelsAsync.valueOrNull ?? const <RefuelEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle details'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AddEditVehicleScreen(vehicle: resolved),
                ),
              );
              if (context.mounted) ref.invalidate(vehiclesProvider);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.marginMobile,
          AppSpacing.marginMobile,
          120,
        ),
        children: [
          Hero(
            tag: 'vehicle-photo-${resolved.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: VehiclePhotoView(vehicle: resolved, height: 180),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Icon(Icons.directions_car, color: cs.primary),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolved.displayName,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            resolved.fuelType.label,
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.stackMd),
                if (resolved.make?.isNotEmpty == true)
                  DetailRow(label: 'Make', value: resolved.make!),
                if (resolved.model?.isNotEmpty == true)
                  DetailRow(label: 'Model', value: resolved.model!),
                if (resolved.year != null)
                  DetailRow(label: 'Year', value: '${resolved.year}'),
                if (resolved.licensePlate?.isNotEmpty == true)
                  DetailRow(label: 'Registration', value: resolved.licensePlate!),
                if (resolved.notes?.isNotEmpty == true)
                  DetailRow(label: 'Notes', value: resolved.notes!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          _StatsStrip(
            entries: refuels,
            fuelType: resolved.fuelType,
            currency: currency,
            distanceUnit: distanceUnit,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          _RecentRefuels(
            entries: refuels,
            vehicle: resolved,
            currency: currency,
            distanceUnit: distanceUnit,
            loading: refuelsAsync.isLoading,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: FilledButton.icon(
            onPressed: () async {
              if (resolved.id == null) return;
              await setActiveVehicle(ref, resolved);
              if (!context.mounted) return;
              await AddRefuelScreen.open(context, vehicleId: resolved.id);
            },
            icon: const Icon(Icons.local_gas_station_outlined),
            label: Text('Log ${FuelTypeMetrics.fillVerb(resolved.fuelType).toLowerCase()}'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.entries,
    required this.fuelType,
    required this.currency,
    required this.distanceUnit,
  });

  final List<RefuelEntry> entries;
  final FuelType fuelType;
  final String currency;
  final String distanceUnit;

  @override
  Widget build(BuildContext context) {
    final totalSpend =
        entries.fold<double>(0, (sum, e) => sum + e.totalPrice);
    final avgEff = FuelCalculations.averageKmPerLiter(entries);

    double? lastOdometer;
    double trackedDistance = 0;
    if (entries.isNotEmpty) {
      final odometers = entries.map((e) => e.odometer).toList()..sort();
      trackedDistance = odometers.last - odometers.first;
      final byDate = [...entries]
        ..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));
      lastOdometer = byDate.first.odometer;
    }

    final tiles = <Widget>[
      _StatTile(
        icon: Icons.route_outlined,
        label: 'Distance tracked',
        value: trackedDistance > 0
            ? '${NumberFormat.decimalPattern().format(trackedDistance.round())} $distanceUnit'
            : '—',
      ),
      _StatTile(
        icon: Icons.payments_outlined,
        label: 'Total spend',
        value: totalSpend > 0
            ? '$currency ${totalSpend.toStringAsFixed(2)}'
            : '—',
      ),
      _StatTile(
        icon: Icons.speed_outlined,
        label: 'Avg efficiency',
        value: FuelTypeMetrics.formatEfficiency(avgEff, fuelType),
      ),
      _StatTile(
        icon: Icons.local_gas_station_outlined,
        label: 'Last odometer',
        value: lastOdometer != null
            ? '${lastOdometer.toStringAsFixed(0)} $distanceUnit'
            : '—',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.gutter,
      crossAxisSpacing: AppSpacing.gutter,
      childAspectRatio: 1.9,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecentRefuels extends StatelessWidget {
  const _RecentRefuels({
    required this.entries,
    required this.vehicle,
    required this.currency,
    required this.distanceUnit,
    required this.loading,
  });

  final List<RefuelEntry> entries;
  final Vehicle vehicle;
  final String currency;
  final String distanceUnit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final cs = context.cs;
    final sorted = [...entries]
      ..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));
    final recent = sorted.take(5).toList();
    final dateFmt = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent activity',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            if (entries.length > recent.length)
              Text(
                'Showing ${recent.length} of ${entries.length}',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recent.isEmpty)
          AppCard(
            child: Row(
              children: [
                Icon(Icons.local_gas_station_outlined,
                    color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Text(
                    'No refuels logged yet for this vehicle.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: 4,
            ),
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  InkWell(
                    onTap: () => RefuelDetailScreen.open(
                      context,
                      entry: recent[i],
                      vehicle: vehicle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFmt.format(recent[i].refuelDate),
                                  style: tt.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  recent[i].stationName?.isNotEmpty == true
                                      ? recent[i].stationName!
                                      : '${recent[i].odometer.toStringAsFixed(0)} $distanceUnit',
                                  style: tt.labelSmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackMd),
                          Text(
                            '$currency ${recent[i].totalPrice.toStringAsFixed(2)}',
                            style: tt.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 20, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
