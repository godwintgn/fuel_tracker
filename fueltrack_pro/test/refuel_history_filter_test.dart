import 'package:flutter_test/flutter_test.dart';
import 'package:fueltrack_pro/data/history_filters.dart';
import 'package:fueltrack_pro/models/enums.dart';
import 'package:fueltrack_pro/models/refuel_entry.dart';
import 'package:fueltrack_pro/models/vehicle.dart';

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
  final vehicles = {1: vehicle};

  RefuelEntry entry({
    required int id,
    required DateTime date,
    FuelType fuel = FuelType.diesel,
    String? station,
  }) {
    return RefuelEntry(
      id: id,
      vehicleId: 1,
      refuelDate: date,
      odometer: 1000 + id.toDouble(),
      quantity: 40,
      pricePerLiter: 0.22,
      totalPrice: 8.8,
      fuelType: fuel,
      stationName: station,
      createdAt: now,
      updatedAt: now,
    );
  }

  final entries = [
    entry(id: 1, date: now.subtract(const Duration(days: 2)), station: 'Shell'),
    entry(
      id: 2,
      date: now.subtract(const Duration(days: 40)),
      station: 'Petron',
      fuel: FuelType.petrol,
    ),
    entry(
      id: 3,
      date: now.subtract(const Duration(days: 100)),
      station: 'Caltex',
    ),
  ];

  test('filters by vehicle', () {
    final result = RefuelHistoryFilter.apply(
      entries: entries,
      filters: const HistoryFilters(vehicleId: 1),
      vehiclesById: vehicles,
      now: now,
    );
    expect(result.length, 3);
  });

  test('filters by fuel type', () {
    final result = RefuelHistoryFilter.apply(
      entries: entries,
      filters: const HistoryFilters(fuelType: FuelType.petrol),
      vehiclesById: vehicles,
      now: now,
    );
    expect(result.length, 1);
    expect(result.first.id, 2);
  });

  test('filters by search query', () {
    final result = RefuelHistoryFilter.apply(
      entries: entries,
      filters: const HistoryFilters(searchQuery: 'shell'),
      vehiclesById: vehicles,
      now: now,
    );
    expect(result.length, 1);
    expect(result.first.stationName, 'Shell');
  });

  test('filters by last 30 days', () {
    final result = RefuelHistoryFilter.apply(
      entries: entries,
      filters: const HistoryFilters(dateRange: HistoryDateRange.last30Days),
      vehiclesById: vehicles,
      now: now,
    );
    expect(result.length, 1);
    expect(result.first.id, 1);
  });

  test('summarize totals entries and spend', () {
    final filtered = RefuelHistoryFilter.apply(
      entries: entries,
      filters: HistoryFilters.defaults,
      vehiclesById: vehicles,
      now: now,
    );
    final summary = RefuelHistoryFilter.summarize(
      entries: filtered,
      filters: HistoryFilters.defaults,
    );
    expect(summary.entryCount, 3);
    expect(summary.totalSpent, closeTo(26.4, 0.01));
  });
}
