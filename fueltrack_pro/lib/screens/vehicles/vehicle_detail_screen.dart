import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vehicle.dart';
import '../../providers/selected_vehicle_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/vehicles/vehicle_photo_view.dart';
import '../refuel/add_refuel_screen.dart';
import 'add_edit_vehicle_screen.dart';

/// Read-only vehicle profile. Edit opens the form screen.
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
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: VehiclePhotoView(vehicle: resolved, height: 180),
          ),
          const SizedBox(height: AppSpacing.gutter),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolved.displayName,
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (resolved.name != resolved.displayName) ...[
                  const SizedBox(height: 4),
                  Text(
                    resolved.name,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: AppSpacing.stackMd),
                _DetailRow(label: 'Fuel type', value: resolved.fuelType.label),
                if (resolved.make?.isNotEmpty == true)
                  _DetailRow(label: 'Make', value: resolved.make!),
                if (resolved.model?.isNotEmpty == true)
                  _DetailRow(label: 'Model', value: resolved.model!),
                if (resolved.year != null)
                  _DetailRow(label: 'Year', value: '${resolved.year}'),
                if (resolved.licensePlate?.isNotEmpty == true)
                  _DetailRow(label: 'Registration', value: resolved.licensePlate!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          FilledButton.icon(
            onPressed: () async {
              if (resolved.id != null) {
                await setActiveVehicle(ref, resolved);
              }
              if (!context.mounted || resolved.id == null) return;
              await AddRefuelScreen.open(context, vehicleId: resolved.id);
            },
            icon: const Icon(Icons.local_gas_station_outlined),
            label: const Text('Log refuel'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
