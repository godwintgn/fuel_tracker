import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fuel_card.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

final fuelCardsProvider =
    AsyncNotifierProvider<FuelCardsNotifier, List<FuelCard>>(
  FuelCardsNotifier.new,
);

class FuelCardsNotifier extends AsyncNotifier<List<FuelCard>> {
  @override
  Future<List<FuelCard>> build() async {
    await ref.watch(databaseInitProvider.future);
    return DatabaseService.instance.getFuelCards();
  }

  Future<void> addCard(FuelCard card) async {
    final id = await DatabaseService.instance.insertFuelCard(card);
    state = AsyncData([
      ...state.valueOrNull ?? [],
      card.copyWith(id: id),
    ]);
  }

  Future<void> updateCard(FuelCard card) async {
    await DatabaseService.instance.updateFuelCard(card);
    state = AsyncData([
      for (final c in state.valueOrNull ?? [])
        if (c.id == card.id) card else c,
    ]);
  }

  Future<void> deleteCard(int id) async {
    await DatabaseService.instance.deleteFuelCard(id);
    state = AsyncData([
      for (final c in state.valueOrNull ?? [])
        if (c.id != id) c,
    ]);
  }
}

/// Cards relevant to a specific vehicle (fleet + vehicle-specific).
final vehicleFuelCardsProvider =
    FutureProvider.family<List<FuelCard>, int>((ref, vehicleId) async {
  await ref.watch(databaseInitProvider.future);
  return DatabaseService.instance.getFuelCards(vehicleId: vehicleId);
});
