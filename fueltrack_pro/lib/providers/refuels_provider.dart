import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/refuel_entry.dart';
import 'database_provider.dart';

final refuelsProvider =
    AsyncNotifierProvider<RefuelsNotifier, List<RefuelEntry>>(RefuelsNotifier.new);

class RefuelsNotifier extends AsyncNotifier<List<RefuelEntry>> {
  @override
  Future<List<RefuelEntry>> build() async {
    await ref.watch(databaseInitProvider.future);
    return ref.read(databaseServiceProvider).getRefuelEntries();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<int> addEntry(RefuelEntry entry) async {
    final id = await ref.read(databaseServiceProvider).insertRefuelEntry(entry);
    ref.invalidateSelf();
    await future;
    return id;
  }

  Future<void> updateEntry(RefuelEntry entry) async {
    await ref.read(databaseServiceProvider).updateRefuelEntry(entry);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteEntry(int id) async {
    await ref.read(databaseServiceProvider).deleteRefuelEntry(id);
    ref.invalidateSelf();
    await future;
  }
}

final vehicleRefuelsProvider =
    FutureProvider.family<List<RefuelEntry>, int>((ref, vehicleId) async {
  await ref.watch(databaseInitProvider.future);
  return ref.read(databaseServiceProvider).getRefuelEntries(vehicleId: vehicleId);
});
