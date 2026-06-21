import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fueltrack_pro/app.dart';
import 'package:fueltrack_pro/models/app_settings.dart';
import 'package:fueltrack_pro/models/vehicle.dart';
import 'package:fueltrack_pro/providers/settings_provider.dart';
import 'package:fueltrack_pro/providers/vehicles_provider.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async =>
      AppSettings.defaults().copyWith(onboardingCompleted: true);
}

class _TestVehiclesNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [];
}

void main() {
  testWidgets('App loads home shell with vehicles tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_TestSettingsNotifier.new),
          vehiclesProvider.overrideWith(_TestVehiclesNotifier.new),
        ],
        child: const FuelTrackApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No vehicles yet'), findsOneWidget);
    expect(find.text('Vehicles'), findsOneWidget);
  });
}
