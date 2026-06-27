import '../models/enums.dart';
import '../models/refuel_entry.dart';
import '../models/vehicle.dart';
import 'fuel_calculations.dart';
import 'fuel_type_metrics.dart';

enum AnalyticsPeriod {
  weekly('7d', 7),
  monthly('30d', 30),
  quarterly('3M', 90),
  yearly('1Y', 365),
  allTime('All', 0);

  const AnalyticsPeriod(this.label, this.days);
  final String label;
  /// 0 means no date filter (all time).
  final int days;
}

// ── Supporting data models ─────────────────────────────────────────────────────

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

/// Per-vehicle efficiency trip data used for the multi-vehicle overlay chart.
class VehicleEfficiencyData {
  const VehicleEfficiencyData({
    required this.vehicle,
    required this.trips,
  });

  final Vehicle vehicle;
  final List<TripEfficiency> trips;
}

/// A single fill-up's cost data, used for the cost-per-fill trend chart.
class FillCostPoint {
  const FillCostPoint({required this.entry});

  final RefuelEntry entry;
  DateTime get date => entry.refuelDate;
  double get totalPrice => entry.totalPrice;
  double? get pricePerLiter => entry.pricePerLiter;
}

/// Aggregated statistics for a single station.
class StationStat {
  const StationStat({
    required this.name,
    required this.visitCount,
    required this.totalSpent,
    this.avgPricePerLiter,
  });

  final String name;
  final int visitCount;
  final double totalSpent;
  final double? avgPricePerLiter;
}

// ── AnalyticsStats ─────────────────────────────────────────────────────────────

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
    required this.fillCostTrend,
    required this.stationStats,
    required this.vehicleEfficiencyData,
    this.bestFill,
    this.worstFill,
    this.nextRefuelPredictionKm,
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

  /// Fill-up cost over time (sorted chronologically).
  final List<FillCostPoint> fillCostTrend;

  /// Stations ranked cheapest-first.
  final List<StationStat> stationStats;

  /// Per-vehicle trip efficiencies for multi-vehicle overlay chart.
  final List<VehicleEfficiencyData> vehicleEfficiencyData;

  /// Refuel entry with the lowest price/L (best deal).
  final RefuelEntry? bestFill;

  /// Refuel entry with the highest price/L (most expensive).
  final RefuelEntry? worstFill;

  /// Estimated km to the next fill based on avg distance per fill.
  final double? nextRefuelPredictionKm;

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
    fillCostTrend: [],
    stationStats: [],
    vehicleEfficiencyData: [],
  );
}

class MonthlySpendPoint {
  const MonthlySpendPoint({required this.key, required this.amount});

  final String key;
  final double amount;

  String get label => FuelCalculations.monthLabel(key);
}

// ── AnalyticsService ───────────────────────────────────────────────────────────

abstract final class AnalyticsService {
  /// Public helpers for PDF reports and other exports.
  static List<StationStat> stationStatsForEntries(List<RefuelEntry> entries) =>
      _stationStats(entries);

  static RefuelEntry? cheapestFill(List<RefuelEntry> entries) =>
      _bestFill(entries);

  static RefuelEntry? costliestFill(List<RefuelEntry> entries) =>
      _worstFill(entries);

  static AnalyticsStats build({
    required List<RefuelEntry> allEntries,
    required List<Vehicle> vehicles,
    required AnalyticsPeriod period,
    FuelType? fuelType,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();

    // allTime period (days == 0) skips the date filter.
    final since = period.days > 0
        ? clock.subtract(Duration(days: period.days))
        : DateTime(2000);

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

    // Monthly spending — show last 6 months for quarterly/yearly/allTime, 3 for shorter
    final monthsToShow = (period == AnalyticsPeriod.yearly ||
            period == AnalyticsPeriod.allTime ||
            period == AnalyticsPeriod.quarterly)
        ? 6
        : 3;

    return AnalyticsStats(
      period: period,
      entries: entries,
      trips: trips,
      avgKmPerLiter: avg,
      litersPer100Km: avg != null ? FuelTypeMetrics.consumptionPer100(avg) : null,
      costPerKm: costPerKm,
      efficiencyChangePercent: _efficiencyChangePercent(trips),
      peakKmPerLiter: peak,
      monthlySpending: _lastMonthsSpending(allEntries, clock, months: monthsToShow),
      vehicleShares: _vehicleShares(entries, vehiclesById),
      fuelTypeShares: _fuelTypeShares(entries),
      vehicleProfiles: _vehicleProfiles(allEntries, vehicles),
      totalLiters: entries.fold<double>(0, (s, e) => s + e.quantity),
      totalSpent: entries.fold<double>(0, (s, e) => s + e.totalPrice),
      fuelType: metricsType,
      fillCostTrend: _fillCostTrend(entries),
      stationStats: _stationStats(entries),
      vehicleEfficiencyData: _vehicleEfficiencyData(entries, vehiclesById),
      bestFill: _bestFill(entries),
      worstFill: _worstFill(entries),
      nextRefuelPredictionKm: _nextRefuelPredictionKm(entries),
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

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
    final lastKeys =
        keys.length > months ? keys.sublist(keys.length - months) : keys;
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

  /// All fill-ups sorted chronologically — used for the cost-per-fill chart.
  static List<FillCostPoint> _fillCostTrend(List<RefuelEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));
    return sorted.map((e) => FillCostPoint(entry: e)).toList();
  }

  /// Stations ranked cheapest avg price-per-liter first.
  static List<StationStat> _stationStats(List<RefuelEntry> entries) {
    final map = <String, _StationAccum>{};
    for (final e in entries) {
      if (e.stationName == null || e.stationName!.trim().isEmpty) continue;
      final key = e.stationName!.trim();
      map.putIfAbsent(key, () => _StationAccum());
      map[key]!.add(e);
    }
    final stats = map.entries.map((kv) => kv.value.toStat(kv.key)).toList();
    // Sort: cheapest avg price first; unknowns last
    stats.sort((a, b) {
      if (a.avgPricePerLiter == null && b.avgPricePerLiter == null) return 0;
      if (a.avgPricePerLiter == null) return 1;
      if (b.avgPricePerLiter == null) return -1;
      return a.avgPricePerLiter!.compareTo(b.avgPricePerLiter!);
    });
    return stats;
  }

  /// Per-vehicle trip efficiency lists for overlay chart.
  static List<VehicleEfficiencyData> _vehicleEfficiencyData(
    List<RefuelEntry> entries,
    Map<int, Vehicle> vehiclesById,
  ) {
    final grouped = <int, List<RefuelEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.vehicleId, () => []).add(e);
    }
    final result = <VehicleEfficiencyData>[];
    for (final kv in grouped.entries) {
      final vehicle = vehiclesById[kv.key];
      if (vehicle == null) continue;
      final trips = FuelCalculations.tripEfficiencies(kv.value);
      if (trips.isEmpty) continue;
      result.add(VehicleEfficiencyData(vehicle: vehicle, trips: trips));
    }
    return result;
  }

  /// Entry with the lowest price-per-liter within the period.
  static RefuelEntry? _bestFill(List<RefuelEntry> entries) {
    final withPrice = entries.where((e) => e.pricePerLiter != null).toList();
    if (withPrice.isEmpty) return null;
    return withPrice.reduce(
      (a, b) => a.pricePerLiter! < b.pricePerLiter! ? a : b,
    );
  }

  /// Entry with the highest price-per-liter within the period.
  static RefuelEntry? _worstFill(List<RefuelEntry> entries) {
    final withPrice = entries.where((e) => e.pricePerLiter != null).toList();
    if (withPrice.isEmpty) return null;
    return withPrice.reduce(
      (a, b) => a.pricePerLiter! > b.pricePerLiter! ? a : b,
    );
  }

  /// Average km per fill-up, used to predict when the next refuel is due.
  static double? _nextRefuelPredictionKm(List<RefuelEntry> entries) {
    if (entries.length < 2) return null;
    final sorted = [...entries]
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));
    final totalDistance =
        sorted.last.odometer - sorted.first.odometer;
    final fills = sorted.length - 1;
    if (fills <= 0 || totalDistance <= 0) return null;
    return totalDistance / fills;
  }
}

// ── Internal accumulator ───────────────────────────────────────────────────────

class _StationAccum {
  int visitCount = 0;
  double totalSpent = 0;
  double priceSum = 0;
  int priceCount = 0;

  void add(RefuelEntry e) {
    visitCount++;
    totalSpent += e.totalPrice;
    if (e.pricePerLiter != null) {
      priceSum += e.pricePerLiter!;
      priceCount++;
    }
  }

  StationStat toStat(String name) => StationStat(
        name: name,
        visitCount: visitCount,
        totalSpent: totalSpent,
        avgPricePerLiter: priceCount > 0 ? priceSum / priceCount : null,
      );
}

// ── copyWithPeriod extension ───────────────────────────────────────────────────

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
      fillCostTrend: fillCostTrend,
      stationStats: stationStats,
      vehicleEfficiencyData: vehicleEfficiencyData,
      bestFill: bestFill,
      worstFill: worstFill,
      nextRefuelPredictionKm: nextRefuelPredictionKm,
    );
  }
}
