import 'package:flutter_test/flutter_test.dart';
import 'package:fueltrack_pro/models/enums.dart';
import 'package:fueltrack_pro/models/refuel_entry.dart';
import 'package:fueltrack_pro/models/vehicle.dart';
import 'package:fueltrack_pro/services/analytics_service.dart';

void main() {
  final now = DateTime(2026, 6, 21, 12);
  final vehicle = Vehicle(
    id: 1,
    name: 'Montero',
    make: 'Mitsubishi',
    model: 'Montero Sport',
    fuelType: FuelType.diesel,
    createdAt: now,
    updatedAt: now,
  );

  RefuelEntry entry({
    required int id,
    required DateTime date,
    required double odometer,
    double quantity = 40,
    double total = 8.8,
  }) {
    return RefuelEntry(
      id: id,
      vehicleId: 1,
      refuelDate: date,
      odometer: odometer,
      quantity: quantity,
      pricePerLiter: total / quantity,
      totalPrice: total,
      fuelType: FuelType.diesel,
      stationName: 'Shell',
      createdAt: now,
      updatedAt: now,
    );
  }

  final entries = [
    entry(id: 1, date: now.subtract(const Duration(days: 90)), odometer: 1000),
    entry(id: 2, date: now.subtract(const Duration(days: 60)), odometer: 1500),
    entry(id: 3, date: now.subtract(const Duration(days: 30)), odometer: 2000),
    entry(id: 4, date: now.subtract(const Duration(days: 5)), odometer: 2500),
  ];

  test('monthly period includes recent refuels only', () {
    final stats = AnalyticsService.build(
      allEntries: entries,
      vehicles: [vehicle],
      period: AnalyticsPeriod.monthly,
      now: now,
    );

    expect(stats.entries.length, 2);
    expect(stats.totalSpent, closeTo(17.6, 0.01));
  });

  test('yearly period includes all refuels', () {
    final stats = AnalyticsService.build(
      allEntries: entries,
      vehicles: [vehicle],
      period: AnalyticsPeriod.yearly,
      now: now,
    );

    expect(stats.entries.length, 4);
    expect(stats.trips.length, 3);
    expect(stats.avgKmPerLiter, isNotNull);
  });

  test('vehicle fuel share sums to 100 percent', () {
    final stats = AnalyticsService.build(
      allEntries: entries,
      vehicles: [vehicle],
      period: AnalyticsPeriod.yearly,
      now: now,
    );

    final totalPercent =
        stats.vehicleShares.fold<double>(0, (s, v) => s + v.percent);
    expect(totalPercent, closeTo(100, 0.1));
    expect(stats.vehicleShares.first.vehicle.id, 1);
  });

  test('monthly spending respects period cap', () {
    final monthlyStats = AnalyticsService.build(
      allEntries: entries,
      vehicles: [vehicle],
      period: AnalyticsPeriod.monthly,
      now: now,
    );
    expect(monthlyStats.monthlySpending.length, lessThanOrEqualTo(3));

    final yearlyStats = AnalyticsService.build(
      allEntries: entries,
      vehicles: [vehicle],
      period: AnalyticsPeriod.yearly,
      now: now,
    );
    expect(yearlyStats.monthlySpending.length, lessThanOrEqualTo(6));
    expect(yearlyStats.monthlySpending.isNotEmpty, isTrue);
  });
}

