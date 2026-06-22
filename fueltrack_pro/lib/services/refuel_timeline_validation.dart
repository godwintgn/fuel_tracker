import '../models/refuel_entry.dart';

/// Chronological bounds for a refuel relative to other entries on the same vehicle.
class RefuelNeighborBounds {
  const RefuelNeighborBounds({this.previous, this.next});

  final RefuelEntry? previous;
  final RefuelEntry? next;
}

class RefuelTimelineValidation {
  static int compareEntries(RefuelEntry a, RefuelEntry b) {
    final byDate = a.refuelDate.compareTo(b.refuelDate);
    if (byDate != 0) return byDate;
    return a.odometer.compareTo(b.odometer);
  }

  static List<RefuelEntry> sortedSiblings(
    List<RefuelEntry> entries, {
    int? excludeId,
  }) {
    return entries
        .where((e) => e.id != excludeId)
        .toList()
      ..sort(compareEntries);
  }

  /// Previous/next by [date] only (before odometer is known).
  static RefuelNeighborBounds neighborsByDate({
    required List<RefuelEntry> entries,
    int? excludeId,
    required DateTime date,
  }) {
    final sorted = sortedSiblings(entries, excludeId: excludeId);
    RefuelEntry? previous;
    RefuelEntry? next;

    for (final entry in sorted) {
      if (entry.refuelDate.isBefore(date)) {
        previous = entry;
      } else if (entry.refuelDate.isAfter(date) && next == null) {
        next = entry;
      }
    }

    return RefuelNeighborBounds(previous: previous, next: next);
  }

  static RefuelNeighborBounds neighbors({
    required List<RefuelEntry> entries,
    int? excludeId,
    required DateTime date,
    required double odometer,
  }) {
    final sorted = sortedSiblings(entries, excludeId: excludeId);
    RefuelEntry? previous;
    RefuelEntry? next;

    for (final entry in sorted) {
      final isBefore = entry.refuelDate.isBefore(date) ||
          (_sameInstant(entry.refuelDate, date) && entry.odometer < odometer);
      final isAfter = entry.refuelDate.isAfter(date) ||
          (_sameInstant(entry.refuelDate, date) && entry.odometer > odometer);

      if (isBefore) previous = entry;
      if (isAfter && next == null) next = entry;
    }

    return RefuelNeighborBounds(previous: previous, next: next);
  }

  static bool _sameInstant(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  static String? validateDateNotFuture(DateTime date) {
    final now = DateTime.now();
    final latest = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (date.isAfter(latest)) {
      return 'Refuel date cannot be in the future';
    }
    return null;
  }

  static String? validateOdometer({
    required double odometer,
    required RefuelNeighborBounds bounds,
    String distanceUnit = 'km',
  }) {
    final prev = bounds.previous;
    final next = bounds.next;

    if (prev != null && odometer <= prev.odometer) {
      return 'Odometer must be above ${prev.odometer.toStringAsFixed(0)} $distanceUnit '
          '(previous entry on ${_formatDate(prev.refuelDate)})';
    }
    if (next != null && odometer >= next.odometer) {
      return 'Odometer must be below ${next.odometer.toStringAsFixed(0)} $distanceUnit '
          '(next entry on ${_formatDate(next.refuelDate)})';
    }
    return null;
  }

  static String? validate({
    required List<RefuelEntry> vehicleEntries,
    int? excludeId,
    required DateTime refuelDate,
    required double odometer,
    String distanceUnit = 'km',
  }) {
    final dateError = validateDateNotFuture(refuelDate);
    if (dateError != null) return dateError;

    final bounds = neighbors(
      entries: vehicleEntries,
      excludeId: excludeId,
      date: refuelDate,
      odometer: odometer,
    );

    return validateOdometer(
      odometer: odometer,
      bounds: bounds,
      distanceUnit: distanceUnit,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
