import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import 'database_provider.dart';
import 'refuels_provider.dart';
import 'selected_vehicle_provider.dart';
import 'vehicles_provider.dart';

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.monthly);

final analyticsProvider = FutureProvider<AnalyticsStats>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final period = ref.watch(analyticsPeriodProvider);
  final allEntries = await ref.watch(refuelsProvider.future);
  final vehicles = await ref.watch(vehiclesProvider.future);
  final activeVehicle = await ref.watch(selectedVehicleProvider.future);

  final entries = activeVehicle?.id != null
      ? allEntries.where((e) => e.vehicleId == activeVehicle!.id).toList()
      : allEntries;

  final scopedVehicles =
      activeVehicle != null ? [activeVehicle] : vehicles;

  return AnalyticsService.build(
    allEntries: entries,
    vehicles: scopedVehicles,
    period: period,
    fuelType: activeVehicle?.fuelType,
  );
});
