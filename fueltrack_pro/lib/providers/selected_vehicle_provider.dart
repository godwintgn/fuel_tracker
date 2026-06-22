import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle.dart';
import 'analytics_provider.dart';
import 'dashboard_provider.dart';
import 'settings_provider.dart';
import 'vehicles_provider.dart';

/// Resolves the active vehicle from settings, falling back to the first vehicle.
final selectedVehicleProvider = FutureProvider<Vehicle?>((ref) async {
  final vehicles = await ref.watch(vehiclesProvider.future);
  if (vehicles.isEmpty) return null;

  final settings = await ref.watch(settingsProvider.future);
  final selectedId = settings.selectedVehicleId;
  if (selectedId != null) {
    for (final v in vehicles) {
      if (v.id == selectedId) return v;
    }
  }
  return vehicles.first;
});

Future<void> setActiveVehicle(WidgetRef ref, Vehicle vehicle) async {
  await HapticFeedback.selectionClick();
  final settings = await ref.read(settingsProvider.future);
  await ref.read(settingsProvider.notifier).updateSettings(
        settings.copyWith(selectedVehicleId: vehicle.id),
      );
  ref
    ..invalidate(selectedVehicleProvider)
    ..invalidate(dashboardProvider)
    ..invalidate(analyticsProvider);
}
