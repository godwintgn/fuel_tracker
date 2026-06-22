import '../models/enums.dart';
import '../models/refuel_entry.dart';
import '../models/vehicle.dart';
import 'fuel_calculations.dart';
import 'fuel_type_metrics.dart';

enum AnalyticsPeriod {
  weekly('Weekly', 7),
  monthly('Monthly', 30),
  yearly('Yearly', 365);

  const AnalyticsPeriod(this.label, this.days);
  final String label;
  final int days;
}

class FuelTypeShare {
  const FuelTypeShare({
    required this.fuelType,
    required this.liters,
    required this.percent,
  });

  final FuelType fuelType;
  final double liters;
  final double percent;
}

class VehicleFuelShare {
  const VehicleFuelShare({
    required this.vehicle,
    required this.liters,
    required this.percent,
  });

  final Vehicle vehicle;
  final double liters;
  final double percent;
}

class VehicleAnalytics {
  const VehicleAnalytics({
    required this.vehicle,
    required this.avgKmPerLiter,
    required this.totalLiters,
    required this.totalSpent,
  });

  final Vehicle vehicle;
  final double? avgKmPerLiter;
  final double totalLiters;
  final double totalSpent;
}

class AnalyticsStats {
  const AnalyticsStats({
    required this.period,
    required this.entries,
    required this.trips,
    required this.avgKmPerLiter,
    required this.litersPer100Km,
    required this.costPerKm,
    required this.efficiencyChangePercent,
    required this.peakKmPerLiter,
    required this.monthlySpending,
    required this.vehicleShares,
    required this.fuelTypeShares,
    required this.vehicleProfiles,
    required this.totalLiters,
    required this.totalSpent,
    this.fuelType = FuelType.petrol,
  });

  final AnalyticsPeriod period;
  final List<RefuelEntry> entries;
  final List<TripEfficiency> trips;
  final double? avgKmPerLiter;
  final double? litersPer100Km;
  final double? costPerKm;
  final double? efficiencyChangePercent;
  final double? peakKmPerLiter;
  final List<MonthlySpendPoint> monthlySpending;
  final List<VehicleFuelShare> vehicleShares;
  final List<FuelTypeShare> fuelTypeShares;
  final List<VehicleAnalytics> vehicleProfiles;
  final double totalLiters;
  final double totalSpent;
  final FuelType fuelType;

  static const empty = AnalyticsStats(
    period: AnalyticsPeriod.monthly,
    entries: [],
    trips: [],
    avgKmPerLiter: null,
    litersPer100Km: null,
    costPerKm: null,
    efficiencyChangePercent: null,
    peakKmPerLiter: null,
    monthlySpending: [],
    vehicleShares: [],
    fuelTypeShares: [],
    vehicleProfiles: [],
    totalLiters: 0,
    totalSpent: 0,
  );
}

class MonthlySpendPoint {
  const MonthlySpendPoint({required this.key, required this.amount});

  final String key;
  final double amount;

  String get label => FuelCalculations.monthLabel(key);
}

abstract final class AnalyticsService {
  static AnalyticsStats build({
    required List<RefuelEntry> allEntries,
    required List<Vehicle> vehicles,
    required AnalyticsPeriod period,
    FuelType? fuelType,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final since = clock.subtract(Duration(days: period.days));
    final entries = allEntries
        .where((e) => !e.refuelDate.isBefore(since))
        .toList()
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));

    if (entries.isEmpty) {
      return AnalyticsStats.empty.copyWithPeriod(period);
    }

    final trips = FuelCalculations.tripEfficiencies(entries);
    final avg = FuelCalculations.averageKmPerLiter(entries);
    final costPerKm = FuelCalculations.costPerKm(entries: entries, since: since);
    final peak = trips.isEmpty
        ? null
        : trips.map((t) => t.kmPerLiter).reduce((a, b) => a > b ? a : b);

    final vehiclesById = {
      for (final v in vehicles)
        if (v.id != null) v.id!: v,
    };

    final metricsType = fuelType ?? entries.first.fuelType;

    return AnalyticsStats(
      period: period,
      entries: entries,
      trips: trips,
      avgKmPerLiter: avg,
      litersPer100Km: avg != null
          ? FuelTypeMetrics.consumptionPer100(avg)
          : null,
      costPerKm: costPerKm,
      efficiencyChangePercent: _efficiencyChangePercent(trips),
      peakKmPerLiter: peak,
      monthlySpending: _lastMonthsSpending(allEntries, clock, months: 3),
      vehicleShares: _vehicleShares(entries, vehiclesById),
      fuelTypeShares: _fuelTypeShares(entries),
      vehicleProfiles: _vehicleProfiles(allEntries, vehicles),
      totalLiters: entries.fold<double>(0, (s, e) => s + e.quantity),
      totalSpent: entries.fold<double>(0, (s, e) => s + e.totalPrice),
      fuelType: metricsType,
    );
  }

  static double? _efficiencyChangePercent(List<TripEfficiency> trips) {
    if (trips.length < 2) return null;

    final midpoint = trips.length ~/ 2;
    final firstHalf = trips.sublist(0, midpoint);
    final secondHalf = trips.sublist(midpoint);

    if (firstHalf.isEmpty || secondHalf.isEmpty) return null;

    final firstAvg =
        firstHalf.fold<double>(0, (s, t) => s + t.kmPerLiter) / firstHalf.length;
    final secondAvg =
        secondHalf.fold<double>(0, (s, t) => s + t.kmPerLiter) / secondHalf.length;

    if (firstAvg <= 0) return null;
    return ((secondAvg - firstAvg) / firstAvg) * 100;
  }

  static List<MonthlySpendPoint> _lastMonthsSpending(
    List<RefuelEntry> entries,
    DateTime now, {
    required int months,
  }) {
    final map = FuelCalculations.monthlySpending(entries);
    final keys = map.keys.toList()..sort();
    final lastKeys = keys.length > months ? keys.sublist(keys.length - months) : keys;
    return lastKeys
        .map((k) => MonthlySpendPoint(key: k, amount: map[k]!))
        .toList();
  }

  static List<VehicleFuelShare> _vehicleShares(
    List<RefuelEntry> entries,
    Map<int, Vehicle> vehiclesById,
  ) {
    final litersByVehicle = <int, double>{};
    for (final entry in entries) {
      litersByVehicle[entry.vehicleId] =
          (litersByVehicle[entry.vehicleId] ?? 0) + entry.quantity;
    }

    final total = litersByVehicle.values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return [];

    return litersByVehicle.entries
        .map((e) {
          final vehicle = vehiclesById[e.key];
          if (vehicle == null) return null;
          return VehicleFuelShare(
            vehicle: vehicle,
            liters: e.value,
            percent: (e.value / total) * 100,
          );
        })
        .whereType<VehicleFuelShare>()
        .toList()
      ..sort((a, b) => b.liters.compareTo(a.liters));
  }

  static List<FuelTypeShare> _fuelTypeShares(List<RefuelEntry> entries) {
    final litersByType = <FuelType, double>{};
    for (final entry in entries) {
      litersByType[entry.fuelType] =
          (litersByType[entry.fuelType] ?? 0) + entry.quantity;
    }

    final total = litersByType.values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return [];

    return litersByType.entries
        .map(
          (e) => FuelTypeShare(
            fuelType: e.key,
            liters: e.value,
            percent: (e.value / total) * 100,
          ),
        )
        .toList()
      ..sort((a, b) => b.liters.compareTo(a.liters));
  }

  static List<VehicleAnalytics> _vehicleProfiles(
    List<RefuelEntry> allEntries,
    List<Vehicle> vehicles,
  ) {
    final profiles = <VehicleAnalytics>[];

    for (final vehicle in vehicles) {
      if (vehicle.id == null) continue;
      final vehicleEntries =
          allEntries.where((e) => e.vehicleId == vehicle.id).toList();
      if (vehicleEntries.isEmpty) continue;

      profiles.add(
        VehicleAnalytics(
          vehicle: vehicle,
          avgKmPerLiter: FuelCalculations.averageKmPerLiter(vehicleEntries),
          totalLiters:
              vehicleEntries.fold<double>(0, (s, e) => s + e.quantity),
          totalSpent:
              vehicleEntries.fold<double>(0, (s, e) => s + e.totalPrice),
        ),
      );
    }

    profiles.sort((a, b) => b.totalLiters.compareTo(a.totalLiters));
    return profiles;
  }
}

extension on AnalyticsStats {
  AnalyticsStats copyWithPeriod(AnalyticsPeriod period) {
    return AnalyticsStats(
      period: period,
      entries: entries,
      trips: trips,
      avgKmPerLiter: avgKmPerLiter,
      litersPer100Km: litersPer100Km,
      costPerKm: costPerKm,
      efficiencyChangePercent: efficiencyChangePercent,
      peakKmPerLiter: peakKmPerLiter,
      monthlySpending: monthlySpending,
      vehicleShares: vehicleShares,
      fuelTypeShares: fuelTypeShares,
      vehicleProfiles: vehicleProfiles,
      totalLiters: totalLiters,
      totalSpent: totalSpent,
      fuelType: fuelType,
    );
  }
}
