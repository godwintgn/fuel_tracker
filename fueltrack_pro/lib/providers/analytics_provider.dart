import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import 'database_provider.dart';
import 'refuels_provider.dart';
import 'vehicles_provider.dart';

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.monthly);

final analyticsProvider = FutureProvider<AnalyticsStats>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final period = ref.watch(analyticsPeriodProvider);
  final entries = await ref.watch(refuelsProvider.future);
  final vehicles = await ref.watch(vehiclesProvider.future);

  return AnalyticsService.build(
    allEntries: entries,
    vehicles: vehicles,
    period: period,
  );
});
