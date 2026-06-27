import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/fuel_card.dart';
import '../../models/vehicle.dart';
import '../../providers/fuel_cards_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/fuel_cards/fuel_card_widget.dart';
import 'add_edit_fuel_card_screen.dart';

class FuelCardListScreen extends ConsumerWidget {
  const FuelCardListScreen({super.key, this.vehicle});

  /// If set, shows cards for a specific vehicle (fleet + vehicle-specific).
  final Vehicle? vehicle;

  static Future<void> open(BuildContext context, {Vehicle? vehicle}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FuelCardListScreen(vehicle: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.cs;
    final tt = context.tt;
    final cardsAsync = ref.watch(fuelCardsProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final currencySymbol = settingsAsync.valueOrNull?.currencySymbol ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          vehicle != null ? '${vehicle!.name} — Cards' : 'Fuel Cards',
          style: tt.titleMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditFuelCardScreen.open(
          context,
          defaultVehicleId: vehicle?.id,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final vehicles = vehiclesAsync.valueOrNull ?? [];
          final cards = vehicle != null
              ? all
                  .where(
                    (c) =>
                        c.scope == FuelCardScope.fleet ||
                        c.vehicleId == vehicle!.id,
                  )
                  .toList()
              : all;

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.credit_card_off_outlined,
                    size: 48,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text(
                    'No fuel cards yet',
                    style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    'Tap + to add your first card',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final fleetCards =
              cards.where((c) => c.scope == FuelCardScope.fleet).toList();
          final vehicleCards =
              cards.where((c) => c.scope == FuelCardScope.vehicle).toList();

          String? vehicleNameFor(FuelCard c) {
            if (c.vehicleId == null) return null;
            return vehicles
                .where((v) => v.id == c.vehicleId)
                .map((v) => v.name)
                .firstOrNull;
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              if (fleetCards.isNotEmpty) ...[
                Text(
                  'Fleet cards',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                ...fleetCards.map(
                  (c) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: FuelCardWidget(
                      card: c,
                      currencySymbol: currencySymbol,
                      onEdit: () => AddEditFuelCardScreen.open(context, card: c),
                      onDelete: () => _confirmDelete(context, ref, c),
                      onToggle: (active) => ref
                          .read(fuelCardsProvider.notifier)
                          .updateCard(c.copyWith(isActive: active)),
                    ),
                  ),
                ),
              ],
              if (vehicleCards.isNotEmpty) ...[
                if (fleetCards.isNotEmpty)
                  const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'Vehicle cards',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                ...vehicleCards.map(
                  (c) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: FuelCardWidget(
                      card: c,
                      currencySymbol: currencySymbol,
                      vehicleName: vehicleNameFor(c),
                      onEdit: () => AddEditFuelCardScreen.open(context, card: c),
                      onDelete: () => _confirmDelete(context, ref, c),
                      onToggle: (active) => ref
                          .read(fuelCardsProvider.notifier)
                          .updateCard(c.copyWith(isActive: active)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FuelCard card,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Remove "${card.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && card.id != null) {
      await ref.read(fuelCardsProvider.notifier).deleteCard(card.id!);
    }
  }
}
