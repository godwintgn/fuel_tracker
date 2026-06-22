import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle.dart';
import '../services/analytics_service.dart';
import '../services/seed_data_service.dart';
import 'database_provider.dart';
import 'refuels_provider.dart';
import 'vehicles_provider.dart';

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.monthly);

final analyticsProvider = FutureProvider<AnalyticsStats>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.read(databaseServiceProvider);

  await SeedDataService(db).seedIfEmpty();
  ref.invalidate(vehiclesProvider);
  ref.invalidate(refuelsProvider);

  final period = ref.watch(analyticsPeriodProvider);
  final entries = await ref.watch(refuelsProvider.future);
  final vehicles = await ref.watch(vehiclesProvider.future);

  return AnalyticsService.build(
    allEntries: entries,
    vehicles: vehicles,
    period: period,
  );
});

class AnalyticsViewModel {
  const AnalyticsViewModel({
    required this.stats,
    required this.vehicles,
  });

  final AnalyticsStats stats;
  final List<Vehicle> vehicles;
}
