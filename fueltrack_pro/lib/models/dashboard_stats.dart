import '../models/refuel_entry.dart';
import '../models/vehicle.dart';
import '../services/fuel_calculations.dart';

class DashboardStats {
  const DashboardStats({
    required this.currentOdometer,
    required this.avgKmPerLiter,
    required this.efficiencyTrendPercent,
    required this.totalSpent30Days,
    required this.totalLiters30Days,
    required this.fillUps30Days,
    required this.costPerKm30Days,
    required this.lastRefuel,
    required this.monthlySpending,
    required this.efficiencyTrend,
  });

  final double? currentOdometer;
  final double? avgKmPerLiter;
  final double? efficiencyTrendPercent;
  final double totalSpent30Days;
  final double totalLiters30Days;
  final int fillUps30Days;
  final double? costPerKm30Days;
  final RefuelEntry? lastRefuel;
  final List<MonthlySpend> monthlySpending;
  final List<TripEfficiency> efficiencyTrend;

  factory DashboardStats.empty() {
    return const DashboardStats(
      currentOdometer: null,
      avgKmPerLiter: null,
      efficiencyTrendPercent: null,
      totalSpent30Days: 0,
      totalLiters30Days: 0,
      fillUps30Days: 0,
      costPerKm30Days: null,
      lastRefuel: null,
      monthlySpending: [],
      efficiencyTrend: [],
    );
  }

  factory DashboardStats.fromEntries(List<RefuelEntry> entries) {
    if (entries.isEmpty) return DashboardStats.empty();

    final sorted = [...entries]
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));
    final now = DateTime.now();
    final since30 = now.subtract(const Duration(days: 30));

    final recent = entries.where((e) => !e.refuelDate.isBefore(since30)).toList();
    final totalSpent =
        recent.fold<double>(0, (sum, e) => sum + e.totalPrice);
    final totalLiters =
        recent.fold<double>(0, (sum, e) => sum + e.quantity);

    final trips = FuelCalculations.tripEfficiencies(entries);
    final avg = FuelCalculations.averageKmPerLiter(entries);

    double? trendPercent;
    if (trips.length >= 2) {
      final latest = trips.last.kmPerLiter;
      final previous = trips[trips.length - 2].kmPerLiter;
      if (previous > 0) {
        trendPercent = ((latest - previous) / previous) * 100;
      }
    }

    final monthlyMap = FuelCalculations.monthlySpending(entries);
    final keys = monthlyMap.keys.toList()..sort();
    final lastFive = keys.length > 5 ? keys.sublist(keys.length - 5) : keys;
    final monthlySpending = lastFive
        .map((k) => MonthlySpend(key: k, amount: monthlyMap[k]!))
        .toList();

    final lastRefuel = [...entries]
      ..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));

    return DashboardStats(
      currentOdometer: sorted.last.odometer,
      avgKmPerLiter: avg,
      efficiencyTrendPercent: trendPercent,
      totalSpent30Days: totalSpent,
      totalLiters30Days: totalLiters,
      fillUps30Days: recent.length,
      costPerKm30Days: FuelCalculations.costPerKm(
        entries: entries,
        since: since30,
      ),
      lastRefuel: lastRefuel.first,
      monthlySpending: monthlySpending,
      efficiencyTrend: trips.length > 6 ? trips.sublist(trips.length - 6) : trips,
    );
  }
}

class MonthlySpend {
  const MonthlySpend({required this.key, required this.amount});

  final String key;
  final double amount;

  String get label => FuelCalculations.monthLabel(key);
}

class DashboardViewModel {
  const DashboardViewModel({
    required this.vehicle,
    required this.allVehicles,
    required this.stats,
  });

  final Vehicle? vehicle;
  final List<Vehicle> allVehicles;
  final DashboardStats stats;
}
