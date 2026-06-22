import '../models/enums.dart';
import '../models/refuel_entry.dart';
import '../models/vehicle.dart';

enum HistoryDateRange {
  all('All time'),
  last7Days('Last 7 days'),
  last30Days('Last month'),
  last3Months('Last 3 months'),
  custom('Custom');

  const HistoryDateRange(this.label);
  final String label;
}

class HistoryFilters {
  const HistoryFilters({
    this.vehicleId,
    this.fuelType,
    this.dateRange = HistoryDateRange.all,
    this.customStart,
    this.customEnd,
    this.searchQuery = '',
  });

  final int? vehicleId;
  final FuelType? fuelType;
  final HistoryDateRange dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String searchQuery;

  bool get hasActiveFilters =>
      vehicleId != null ||
      fuelType != null ||
      dateRange != HistoryDateRange.all ||
      searchQuery.trim().isNotEmpty;

  HistoryFilters copyWith({
    int? vehicleId,
    FuelType? fuelType,
    HistoryDateRange? dateRange,
    DateTime? customStart,
    DateTime? customEnd,
    String? searchQuery,
    bool clearVehicle = false,
    bool clearFuelType = false,
    bool clearCustomDates = false,
  }) {
    return HistoryFilters(
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
      fuelType: clearFuelType ? null : (fuelType ?? this.fuelType),
      dateRange: dateRange ?? this.dateRange,
      customStart:
          clearCustomDates ? null : (customStart ?? this.customStart),
      customEnd: clearCustomDates ? null : (customEnd ?? this.customEnd),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  static const defaults = HistoryFilters();
}

class HistoryListSummary {
  const HistoryListSummary({
    required this.entryCount,
    required this.totalSpent,
    required this.periodLabel,
  });

  final int entryCount;
  final double totalSpent;
  final String periodLabel;
}

abstract final class RefuelHistoryFilter {
  static List<RefuelEntry> apply({
    required List<RefuelEntry> entries,
    required HistoryFilters filters,
    required Map<int, Vehicle> vehiclesById,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    var result = List<RefuelEntry>.from(entries);

    if (filters.vehicleId != null) {
      result = result.where((e) => e.vehicleId == filters.vehicleId).toList();
    }

    if (filters.fuelType != null) {
      result = result.where((e) => e.fuelType == filters.fuelType).toList();
    }

    final range = _dateRangeBounds(filters, clock);
    if (range != null) {
      result = result
          .where(
            (e) =>
                !e.refuelDate.isBefore(range.$1) &&
                !e.refuelDate.isAfter(range.$2),
          )
          .toList();
    }

    final query = filters.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((e) {
        final vehicle = vehiclesById[e.vehicleId];
        final haystack = [
          e.stationName,
          e.notes,
          e.fuelType.label,
          vehicle?.displayName,
          vehicle?.name,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    result.sort((a, b) => b.refuelDate.compareTo(a.refuelDate));
    return result;
  }

  static HistoryListSummary summarize({
    required List<RefuelEntry> entries,
    required HistoryFilters filters,
  }) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.totalPrice);
    final periodLabel = switch (filters.dateRange) {
      HistoryDateRange.all => 'All time',
      HistoryDateRange.last7Days => 'Last 7 days',
      HistoryDateRange.last30Days => 'Last month',
      HistoryDateRange.last3Months => 'Last 3 months',
      HistoryDateRange.custom => 'Custom range',
    };

    return HistoryListSummary(
      entryCount: entries.length,
      totalSpent: total,
      periodLabel: periodLabel,
    );
  }

  static (DateTime, DateTime)? _dateRangeBounds(
    HistoryFilters filters,
    DateTime now,
  ) {
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (filters.dateRange) {
      case HistoryDateRange.all:
        return null;
      case HistoryDateRange.last7Days:
        return (end.subtract(const Duration(days: 6)), end);
      case HistoryDateRange.last30Days:
        return (end.subtract(const Duration(days: 29)), end);
      case HistoryDateRange.last3Months:
        return (DateTime(end.year, end.month - 3, end.day), end);
      case HistoryDateRange.custom:
        if (filters.customStart == null || filters.customEnd == null) {
          return null;
        }
        final start = DateTime(
          filters.customStart!.year,
          filters.customStart!.month,
          filters.customStart!.day,
        );
        final customEnd = DateTime(
          filters.customEnd!.year,
          filters.customEnd!.month,
          filters.customEnd!.day,
          23,
          59,
          59,
        );
        return (start, customEnd);
    }
  }
}
