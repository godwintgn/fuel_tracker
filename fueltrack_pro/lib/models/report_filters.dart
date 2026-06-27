/// Preset and custom ranges for PDF fuel reports.
enum ReportPeriod {
  last7Days('7 days', 7),
  last30Days('30 days', 30),
  last3Months('3 months', 90),
  last6Months('6 months', 180),
  lastYear('1 year', 365),
  allTime('All time', 0),
  custom('Custom', -1);

  const ReportPeriod(this.label, this.days);
  final String label;

  /// 0 = all time, -1 = use [ReportFilters.customStart/customEnd].
  final int days;
}

class ReportFilters {
  const ReportFilters({
    this.period = ReportPeriod.last30Days,
    this.customStart,
    this.customEnd,
    this.vehicleIds = const {},
  });

  final ReportPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;

  /// Empty set means all vehicles.
  final Set<int> vehicleIds;

  bool get allVehicles => vehicleIds.isEmpty;

  ReportFilters copyWith({
    ReportPeriod? period,
    DateTime? customStart,
    DateTime? customEnd,
    Set<int>? vehicleIds,
    bool clearCustomRange = false,
  }) {
    return ReportFilters(
      period: period ?? this.period,
      customStart: clearCustomRange ? null : (customStart ?? this.customStart),
      customEnd: clearCustomRange ? null : (customEnd ?? this.customEnd),
      vehicleIds: vehicleIds ?? this.vehicleIds,
    );
  }

  /// Inclusive calendar-day range ending at [now]'s date.
  ({DateTime start, DateTime end}) resolveRange(DateTime now) {
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    if (period == ReportPeriod.custom) {
      final start = customStart != null
          ? DateTime(
              customStart!.year,
              customStart!.month,
              customStart!.day,
            )
          : end.subtract(const Duration(days: 30));
      final customEndDay = customEnd != null
          ? DateTime(
              customEnd!.year,
              customEnd!.month,
              customEnd!.day,
              23,
              59,
              59,
              999,
            )
          : end;
      return (start: start, end: customEndDay);
    }

    if (period == ReportPeriod.allTime || period.days <= 0) {
      return (start: DateTime(2000), end: end);
    }

    final startDay = end.subtract(Duration(days: period.days - 1));
    final start = DateTime(startDay.year, startDay.month, startDay.day);
    return (start: start, end: end);
  }
}
