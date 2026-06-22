import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import '../models/refuel_entry.dart';
import '../models/vehicle.dart';
import 'database_provider.dart';
import 'settings_provider.dart';
import 'vehicles_provider.dart';

final dashboardProvider = FutureProvider<DashboardViewModel>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.read(databaseServiceProvider);

  final vehicles = await ref.watch(vehiclesProvider.future);
  final settings = await ref.watch(settingsProvider.future);

  Vehicle? vehicle;
  if (settings.selectedVehicleId != null) {
    for (final v in vehicles) {
      if (v.id == settings.selectedVehicleId) {
        vehicle = v;
        break;
      }
    }
  }
  vehicle ??= vehicles.isNotEmpty ? vehicles.first : null;

  var entries = <RefuelEntry>[];
  if (vehicle?.id != null) {
    entries = await db.getRefuelEntries(vehicleId: vehicle!.id);
  }

  return DashboardViewModel(
    vehicle: vehicle,
    allVehicles: vehicles,
    stats: DashboardStats.fromEntries(entries),
  );
});
