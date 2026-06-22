import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/fuel_type_metrics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/app_card.dart';
import 'add_refuel_screen.dart';

/// Read-only refuel entry view. Edit opens the form screen.
class RefuelDetailScreen extends ConsumerWidget {
  const RefuelDetailScreen({
    super.key,
    required this.entry,
    this.vehicle,
  });

  final RefuelEntry entry;
  final Vehicle? vehicle;

  static Future<void> open(
    BuildContext context, {
    required RefuelEntry entry,
    Vehicle? vehicle,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RefuelDetailScreen(entry: entry, vehicle: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final currency = settings?.currencySymbol ?? r'$';
    final distanceUnit = settings?.distanceUnit.abbreviation ?? 'km';
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];
    final resolvedVehicle = vehicle ??
        vehicles.cast<Vehicle?>().firstWhere(
              (v) => v?.id == entry.vehicleId,
              orElse: () => null,
            );
    final fuelType = resolvedVehicle?.fuelType ?? entry.fuelType;
    final qtyUnit = FuelTypeMetrics.quantityUnit(fuelType);
    final priceLabel = FuelTypeMetrics.pricePerQuantityLabel(fuelType);
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text('${FuelTypeMetrics.fillVerb(fuelType)} details'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AddRefuelScreen(entry: entry),
                ),
              );
              if (context.mounted) {
                ref.invalidate(refuelsProvider);
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          if (resolvedVehicle != null)
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.directions_car, color: context.cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resolvedVehicle.displayName,
                          style: context.tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          resolvedVehicle.fuelType.label,
                          style: context.tt.bodySmall?.copyWith(
                            color: context.cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.gutter),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Date & time',
                  value: dateFmt.format(entry.refuelDate),
                ),
                _DetailRow(
                  label: 'Odometer',
                  value:
                      '${entry.odometer.toStringAsFixed(0)} $distanceUnit',
                ),
                _DetailRow(
                  label: FuelTypeMetrics.quantityFieldLabel(fuelType),
                  value: '${entry.quantity.toStringAsFixed(2)} $qtyUnit',
                ),
                if (entry.pricePerLiter != null)
                  _DetailRow(
                    label: priceLabel,
                    value:
                        '$currency ${entry.pricePerLiter!.toStringAsFixed(3)}',
                  ),
                _DetailRow(
                  label: 'Total cost',
                  value: '$currency ${entry.totalPrice.toStringAsFixed(3)}',
                  emphasized: true,
                ),
                if (entry.stationName?.isNotEmpty == true)
                  _DetailRow(label: 'Station', value: entry.stationName!),
                if (entry.notes?.isNotEmpty == true)
                  _DetailRow(label: 'Notes', value: entry.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: (emphasized ? tt.titleMedium : tt.bodyLarge)?.copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
