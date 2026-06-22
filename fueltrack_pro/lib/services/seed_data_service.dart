import '../models/enums.dart';
import '../models/refuel_entry.dart';
import '../models/vehicle.dart';
import 'database_service.dart';

/// Development-only seed data. Remove before final wiring (Step 9).
class SeedDataService {
  SeedDataService(this._db);

  final DatabaseService _db;

  Future<void> seedIfEmpty() async {
    final refuels = await _db.getRefuelEntries();
    if (refuels.isNotEmpty) return;

    final now = DateTime.now();
    var vehicleId = await _ensureSeedVehicle(now);
    await _seedRefuels(vehicleId, now);
    await _ensureOmrSettings();
  }

  Future<int> _ensureSeedVehicle(DateTime now) async {
    final vehicles = await _db.getVehicles();
    final existing = vehicles.where(
      (v) =>
          v.model?.toLowerCase().contains('montero') == true ||
          v.name.toLowerCase().contains('montero'),
    );

    if (existing.isNotEmpty) {
      return existing.first.id!;
    }

    return _db.insertVehicle(
      Vehicle(
        name: 'Mitsubishi Montero Sport',
        make: 'Mitsubishi',
        model: 'Montero Sport',
        year: 2023,
        fuelType: FuelType.diesel,
        licensePlate: 'ABC-1234',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _ensureOmrSettings() async {
    final settings = await _db.getSettings();
    if (settings.currencyCode == 'OMR') return;

    await _db.saveSettings(
      settings.copyWith(
        currencyCode: 'OMR',
        currencySymbol: 'OMR',
        distanceUnit: DistanceUnit.km,
        fuelUnit: FuelUnit.liters,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _seedRefuels(int vehicleId, DateTime now) async {
    final templates = [
      (daysAgo: 88, odometer: 41200.0, liters: 48.0, price: 0.218, station: 'Oman Oil Ruwi'),
      (daysAgo: 74, odometer: 41780.0, liters: 42.0, price: 0.219, station: 'Shell Al Khuwair'),
      (daysAgo: 60, odometer: 42350.0, liters: 45.0, price: 0.220, station: 'Shell Al Khuwair'),
      (daysAgo: 45, odometer: 42920.0, liters: 44.0, price: 0.220, station: 'PDO Fuel Station'),
      (daysAgo: 30, odometer: 43510.0, liters: 46.0, price: 0.221, station: 'Oman Oil Ruwi'),
      (daysAgo: 21, odometer: 44080.0, liters: 43.0, price: 0.220, station: 'Shell Al Khuwair'),
      (daysAgo: 10, odometer: 44650.0, liters: 47.0, price: 0.220, station: 'Shell Al Khuwair'),
      (daysAgo: 3, odometer: 45230.0, liters: 45.0, price: 0.220, station: 'Shell Al Khuwair'),
    ];

    for (final t in templates) {
      final date = now.subtract(Duration(days: t.daysAgo));
      final total = t.liters * t.price;
      await _db.insertRefuelEntry(
        RefuelEntry(
          vehicleId: vehicleId,
          refuelDate: date,
          odometer: t.odometer,
          quantity: t.liters,
          pricePerLiter: t.price,
          totalPrice: double.parse(total.toStringAsFixed(3)),
          fuelType: FuelType.diesel,
          stationName: t.station,
          createdAt: date,
          updatedAt: date,
        ),
      );
    }

    final settings = await _db.getSettings();
    await _db.saveSettings(
      settings.copyWith(
        selectedVehicleId: vehicleId,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
