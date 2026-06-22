import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fueltrack_pro/app.dart';
import 'package:fueltrack_pro/models/app_settings.dart';
import 'package:fueltrack_pro/models/dashboard_stats.dart';
import 'package:fueltrack_pro/models/enums.dart';
import 'package:fueltrack_pro/models/refuel_entry.dart';
import 'package:fueltrack_pro/models/vehicle.dart';
import 'package:fueltrack_pro/providers/dashboard_provider.dart';
import 'package:fueltrack_pro/providers/settings_provider.dart';
import 'package:fueltrack_pro/providers/vehicles_provider.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async => AppSettings.defaults().copyWith(
        onboardingCompleted: true,
        currencyCode: 'OMR',
        currencySymbol: 'OMR',
        selectedVehicleId: 1,
      );
}

class _TestVehiclesNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [
        Vehicle(
          id: 1,
          name: 'Mitsubishi Montero Sport',
          make: 'Mitsubishi',
          model: 'Montero Sport',
          fuelType: FuelType.diesel,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
}

class _TestDashboard {
  static DashboardViewModel build() => DashboardViewModel(
        vehicle: Vehicle(
          id: 1,
          name: 'Mitsubishi Montero Sport',
          make: 'Mitsubishi',
          model: 'Montero Sport',
          fuelType: FuelType.diesel,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        allVehicles: [
          Vehicle(
            id: 1,
            name: 'Mitsubishi Montero Sport',
            make: 'Mitsubishi',
            model: 'Montero Sport',
            fuelType: FuelType.diesel,
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ],
        stats: DashboardStats(
          currentOdometer: 45230,
          avgKmPerLiter: 12.5,
          efficiencyTrendPercent: 4,
          totalSpent30Days: 45.2,
          totalLiters30Days: 240,
          fillUps30Days: 4,
          costPerKm30Days: 0.045,
          lastRefuel: RefuelEntry(
            vehicleId: 1,
            refuelDate: DateTime.now().subtract(const Duration(days: 3)),
            odometer: 45230,
            quantity: 45,
            pricePerLiter: 0.22,
            totalPrice: 9.9,
            fuelType: FuelType.diesel,
            stationName: 'Shell Al Khuwair',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          monthlySpending: const [
            MonthlySpend(key: '2026-03', amount: 30),
            MonthlySpend(key: '2026-04', amount: 45),
          ],
          efficiencyTrend: const [],
        ),
      );
}

void main() {
  testWidgets('App loads dashboard tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_TestSettingsNotifier.new),
          vehiclesProvider.overrideWith(_TestVehiclesNotifier.new),
          dashboardProvider.overrideWith((ref) async => _TestDashboard.build()),
        ],
        child: const FuelTrackApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Quick Overview'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
