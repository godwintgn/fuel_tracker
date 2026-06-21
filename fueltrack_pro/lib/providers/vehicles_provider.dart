import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle.dart';
import 'database_provider.dart';

final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(VehiclesNotifier.new);

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    await ref.watch(databaseInitProvider.future);
    return ref.read(databaseServiceProvider).getVehicles();
  }

  Future<int> addVehicle(Vehicle vehicle) async {
    final id = await ref.read(databaseServiceProvider).insertVehicle(vehicle);
    ref.invalidateSelf();
    await future;
    return id;
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await ref.read(databaseServiceProvider).updateVehicle(vehicle);
    ref.invalidateSelf();
  }

  Future<void> deleteVehicle(int id) async {
    await ref.read(databaseServiceProvider).deleteVehicle(id);
    ref.invalidateSelf();
  }
}
