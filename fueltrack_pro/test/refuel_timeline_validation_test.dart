import 'package:flutter_test/flutter_test.dart';
import 'package:fueltrack_pro/models/enums.dart';
import 'package:fueltrack_pro/models/refuel_entry.dart';
import 'package:fueltrack_pro/services/refuel_timeline_validation.dart';

void main() {
  final base = DateTime(2024, 1, 1);

  RefuelEntry entry({
    int? id,
    required DateTime date,
    required double odometer,
  }) {
    return RefuelEntry(
      id: id,
      vehicleId: 1,
      refuelDate: date,
      odometer: odometer,
      quantity: 40,
      pricePerLiter: 0.5,
      totalPrice: 20,
      fuelType: FuelType.petrol,
      createdAt: base,
      updatedAt: base,
    );
  }

  test('rejects odometer not above previous entry', () {
    final entries = [
      entry(id: 1, date: DateTime(2024, 6, 1), odometer: 10_000),
      entry(id: 2, date: DateTime(2024, 7, 1), odometer: 10_500),
    ];

    final error = RefuelTimelineValidation.validate(
      vehicleEntries: entries,
      refuelDate: DateTime(2024, 8, 1),
      odometer: 10_400,
    );

    expect(error, isNotNull);
    expect(error, contains('above'));
  });

  test('rejects odometer not below next entry when backfilling history', () {
    final entries = [
      entry(id: 1, date: DateTime(2024, 6, 1), odometer: 10_000),
      entry(id: 2, date: DateTime(2024, 8, 1), odometer: 10_500),
    ];

    final error = RefuelTimelineValidation.validate(
      vehicleEntries: entries,
      refuelDate: DateTime(2024, 7, 1),
      odometer: 10_600,
    );

    expect(error, isNotNull);
    expect(error, contains('below'));
  });

  test('allows valid historical insert between two entries', () {
    final entries = [
      entry(id: 1, date: DateTime(2024, 6, 1), odometer: 10_000),
      entry(id: 2, date: DateTime(2024, 8, 1), odometer: 10_500),
    ];

    final error = RefuelTimelineValidation.validate(
      vehicleEntries: entries,
      refuelDate: DateTime(2024, 7, 1),
      odometer: 10_250,
    );

    expect(error, isNull);
  });

  test('excludes current entry when editing', () {
    final entries = [
      entry(id: 1, date: DateTime(2024, 6, 1), odometer: 10_000),
      entry(id: 2, date: DateTime(2024, 7, 1), odometer: 10_500),
    ];

    final error = RefuelTimelineValidation.validate(
      vehicleEntries: entries,
      excludeId: 2,
      refuelDate: DateTime(2024, 7, 1),
      odometer: 10_520,
    );

    expect(error, isNull);
  });
}
