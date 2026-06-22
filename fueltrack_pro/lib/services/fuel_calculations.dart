import '../models/refuel_entry.dart';

class TripEfficiency {
  const TripEfficiency({
    required this.refuelDate,
    required this.kmPerLiter,
    required this.distanceKm,
    required this.liters,
  });

  final DateTime refuelDate;
  final double kmPerLiter;
  final double distanceKm;
  final double liters;
}

abstract final class FuelCalculations {
  /// km/L = distance between consecutive refuels ÷ liters at the later refuel.
  static List<TripEfficiency> tripEfficiencies(List<RefuelEntry> entries) {
    if (entries.length < 2) return [];

    final sorted = [...entries]
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));

    final trips = <TripEfficiency>[];
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final current = sorted[i];
      final distance = current.odometer - previous.odometer;
      if (distance <= 0 || current.quantity <= 0) continue;

      trips.add(
        TripEfficiency(
          refuelDate: current.refuelDate,
          kmPerLiter: distance / current.quantity,
          distanceKm: distance,
          liters: current.quantity,
        ),
      );
    }
    return trips;
  }

  static double? averageKmPerLiter(List<RefuelEntry> entries) {
    final trips = tripEfficiencies(entries);
    if (trips.isEmpty) return null;
    final total = trips.fold<double>(0, (sum, t) => sum + t.kmPerLiter);
    return total / trips.length;
  }

  static double litersPer100Km(double kmPerLiter) {
    if (kmPerLiter <= 0) return 0;
    return (100 / kmPerLiter);
  }

  static double? costPerKm({
    required List<RefuelEntry> entries,
    required DateTime since,
  }) {
    final trips = tripEfficiencies(entries);
    if (trips.isEmpty) return null;

    final sorted = [...entries]
      ..sort((a, b) => a.refuelDate.compareTo(b.refuelDate));

    var totalCost = 0.0;
    var totalDistance = 0.0;

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      if (current.refuelDate.isBefore(since)) continue;
      final distance = current.odometer - sorted[i - 1].odometer;
      if (distance > 0) {
        totalDistance += distance;
        totalCost += current.totalPrice;
      }
    }

    if (totalDistance <= 0) return null;
    return totalCost / totalDistance;
  }

  static Map<String, double> monthlySpending(List<RefuelEntry> entries) {
    final spending = <String, double>{};
    for (final entry in entries) {
      final key = _monthKey(entry.refuelDate);
      spending[key] = (spending[key] ?? 0) + entry.totalPrice;
    }
    return spending;
  }

  static String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  static String monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return key;
    return months[month - 1];
  }
}
