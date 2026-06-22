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
}

final vehicleRefuelsProvider =
    FutureProvider.family<List<RefuelEntry>, int>((ref, vehicleId) async {
  await ref.watch(databaseInitProvider.future);
  return ref.read(databaseServiceProvider).getRefuelEntries(vehicleId: vehicleId);
});
