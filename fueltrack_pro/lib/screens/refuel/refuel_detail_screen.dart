import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/fuel_type_metrics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/detail_row.dart';
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

    final siblings = ref.watch(vehicleRefuelsProvider(entry.vehicleId)).valueOrNull ??
        const <RefuelEntry>[];
    final fillEfficiency = _fillEfficiency(siblings);

    return Scaffold(
      appBar: AppBar(
        title: Text('${FuelTypeMetrics.fillVerb(fuelType)} details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          _CostHero(
            currency: currency,
            total: entry.totalPrice,
            quantity: entry.quantity,
            qtyUnit: qtyUnit,
            pricePerUnit: entry.pricePerLiter,
            fuelType: fuelType,
          ),
          const SizedBox(height: AppSpacing.gutter),
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
                DetailRow(
                  label: 'Date & time',
                  value: dateFmt.format(entry.refuelDate),
                ),
                DetailRow(
                  label: 'Odometer',
                  value:
                      '${entry.odometer.toStringAsFixed(0)} $distanceUnit',
                ),
                DetailRow(
                  label: FuelTypeMetrics.quantityFieldLabel(fuelType),
                  value: '${entry.quantity.toStringAsFixed(2)} $qtyUnit',
                ),
                if (entry.pricePerLiter != null)
                  DetailRow(
                    label: priceLabel,
                    value:
                        '$currency ${entry.pricePerLiter!.toStringAsFixed(3)}',
                  ),
                if (fillEfficiency != null)
                  DetailRow(
                    label: 'Efficiency (this fill)',
                    value: FuelTypeMetrics.formatEfficiency(
                      fillEfficiency,
                      fuelType,
                    ),
                    emphasized: true,
                  ),
                if (entry.stationName?.isNotEmpty == true)
                  DetailRow(label: 'Station', value: entry.stationName!),
                if (entry.notes?.isNotEmpty == true)
                  DetailRow(label: 'Notes', value: entry.notes!),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context, ref),
                  icon: Icon(Icons.delete_outline, color: context.cs.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: context.cs.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: context.cs.error),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _edit(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddRefuelScreen(entry: entry),
      ),
    );
    if (context.mounted) {
      ref.invalidate(refuelsProvider);
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (entry.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete refuel?'),
        content: const Text(
          'This entry will be removed from your history and dashboard stats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.cs.error,
              foregroundColor: context.cs.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(refuelsProvider.notifier).deleteEntry(entry.id!);
    ref
      ..invalidate(dashboardProvider)
      ..invalidate(vehicleRefuelsProvider(entry.vehicleId));

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refuel entry deleted')),
      );
    }
  }

  /// km/L (etc.) for this fill: distance since the previous refuel ÷ quantity.
  double? _fillEfficiency(List<RefuelEntry> siblings) {
    if (entry.quantity <= 0 || siblings.isEmpty) return null;
    final sorted = [...siblings]
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));

    RefuelEntry? previous;
    for (final s in sorted) {
      final isBefore = s.refuelDate.isBefore(entry.refuelDate) ||
          (s.refuelDate.isAtSameMomentAs(entry.refuelDate) &&
              s.odometer < entry.odometer);
      if (s.id != entry.id && isBefore) previous = s;
    }
    if (previous == null) return null;

    final distance = entry.odometer - previous.odometer;
    if (distance <= 0) return null;
    return distance / entry.quantity;
  }
}

class _CostHero extends StatelessWidget {
  const _CostHero({
    required this.currency,
    required this.total,
    required this.quantity,
    required this.qtyUnit,
    required this.pricePerUnit,
    required this.fuelType,
  });

  final String currency;
  final double total;
  final double quantity;
  final String qtyUnit;
  final double? pricePerUnit;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final cs = context.cs;
    final pal = context.palette;
    final subtitle = StringBuffer('${quantity.toStringAsFixed(2)} $qtyUnit');
    if (pricePerUnit != null) {
      subtitle.write(' • ${pricePerUnit!.toStringAsFixed(3)} $currency/$qtyUnit');
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: pal.spend.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(Icons.account_balance_wallet_outlined, color: pal.spend),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total cost',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  '$currency ${total.toStringAsFixed(3)}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: pal.spend,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.toString(),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
