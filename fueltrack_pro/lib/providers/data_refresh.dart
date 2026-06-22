import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_provider.dart';
import 'dashboard_provider.dart';
import 'refuels_provider.dart';
import 'settings_provider.dart';
import 'vehicles_provider.dart';

void invalidateAllDataProviders(WidgetRef ref) {
  ref.invalidate(settingsProvider);
  ref.invalidate(vehiclesProvider);
  ref.invalidate(refuelsProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(analyticsProvider);
}
