import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_record.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

/// All service records (active only by default, used for dashboard warnings).
final activeServiceRecordsProvider =
    FutureProvider<List<ServiceRecord>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  return DatabaseService.instance.getServiceRecords(activeOnly: true);
});

/// Service records for a specific vehicle.
final vehicleServiceRecordsProvider =
    AsyncNotifierProvider.family<VehicleServiceRecordsNotifier, List<ServiceRecord>, int>(
  VehicleServiceRecordsNotifier.new,
);

class VehicleServiceRecordsNotifier
    extends FamilyAsyncNotifier<List<ServiceRecord>, int> {
  @override
  Future<List<ServiceRecord>> build(int arg) async {
    await ref.watch(databaseInitProvider.future);
    return DatabaseService.instance.getServiceRecords(vehicleId: arg);
  }

  Future<void> add(ServiceRecord record) async {
    final id = await DatabaseService.instance.insertServiceRecord(record);
    state = AsyncData([...state.valueOrNull ?? [], record.copyWith(id: id)]);
  }

  Future<void> save(ServiceRecord record) async {
    await DatabaseService.instance.updateServiceRecord(record);
    state = AsyncData([
      for (final r in state.valueOrNull ?? [])
        if (r.id == record.id) record else r,
    ]);
  }

  Future<void> remove(int id) async {
    await DatabaseService.instance.deleteServiceRecord(id);
    state = AsyncData([
      for (final r in state.valueOrNull ?? []) if (r.id != id) r,
    ]);
  }

  Future<void> complete(ServiceRecord record, {DateTime? nextDate, double? nextOdometer}) async {
    final now = DateTime.now();
    final completed = record.copyWith(
      isCompleted: true,
      completedDate: now,
      nextDueDate: nextDate,
      nextDueOdometer: nextOdometer,
      updatedAt: now,
    );
    await DatabaseService.instance.updateServiceRecord(completed);

    // If next service was given, create it as a new record
    if (nextDate != null || nextOdometer != null) {
      final next = ServiceRecord(
        vehicleId: record.vehicleId,
        title: record.title,
        notes: record.notes,
        triggerType: record.triggerType,
        dueDate: nextDate,
        dueOdometer: nextOdometer,
        notifyBeforeDays: record.notifyBeforeDays,
        notifyBeforeKm: record.notifyBeforeKm,
        createdAt: now,
        updatedAt: now,
      );
      final newId = await DatabaseService.instance.insertServiceRecord(next);
      state = AsyncData([
        for (final r in state.valueOrNull ?? [])
          if (r.id == record.id) completed else r,
        next.copyWith(id: newId),
      ]);
    } else {
      state = AsyncData([
        for (final r in state.valueOrNull ?? [])
          if (r.id == record.id) completed else r,
      ]);
    }
  }
}
