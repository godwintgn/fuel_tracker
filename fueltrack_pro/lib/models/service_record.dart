import 'enums.dart';

class ServiceRecord {
  const ServiceRecord({
    this.id,
    required this.vehicleId,
    required this.title,
    this.notes,
    required this.triggerType,
    this.dueDate,
    this.dueOdometer,
    this.notifyBeforeDays = 7,
    this.notifyBeforeKm,
    this.isCompleted = false,
    this.completedDate,
    this.nextDueDate,
    this.nextDueOdometer,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int vehicleId;
  final String title;
  final String? notes;
  final ServiceTriggerType triggerType;
  final DateTime? dueDate;
  final double? dueOdometer;
  final int notifyBeforeDays;
  final double? notifyBeforeKm;
  final bool isCompleted;
  final DateTime? completedDate;
  final DateTime? nextDueDate;
  final double? nextDueOdometer;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverdue {
    if (isCompleted) return false;
    if (dueDate != null && dueDate!.isBefore(DateTime.now())) return true;
    return false;
  }

  bool isDueSoon({double? currentOdometer}) {
    if (isCompleted) return false;
    final now = DateTime.now();
    if (dueDate != null) {
      final diff = dueDate!.difference(now).inDays;
      if (diff >= 0 && diff <= notifyBeforeDays) return true;
    }
    if (dueOdometer != null &&
        currentOdometer != null &&
        notifyBeforeKm != null) {
      final remaining = dueOdometer! - currentOdometer;
      if (remaining >= 0 && remaining <= notifyBeforeKm!) return true;
    }
    return false;
  }

  ServiceRecord copyWith({
    int? id,
    int? vehicleId,
    String? title,
    String? notes,
    ServiceTriggerType? triggerType,
    DateTime? dueDate,
    bool clearDueDate = false,
    double? dueOdometer,
    bool clearDueOdometer = false,
    int? notifyBeforeDays,
    double? notifyBeforeKm,
    bool clearNotifyKm = false,
    bool? isCompleted,
    DateTime? completedDate,
    DateTime? nextDueDate,
    bool clearNextDate = false,
    double? nextDueOdometer,
    bool clearNextOdometer = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      triggerType: triggerType ?? this.triggerType,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueOdometer: clearDueOdometer ? null : (dueOdometer ?? this.dueOdometer),
      notifyBeforeDays: notifyBeforeDays ?? this.notifyBeforeDays,
      notifyBeforeKm: clearNotifyKm ? null : (notifyBeforeKm ?? this.notifyBeforeKm),
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      nextDueDate: clearNextDate ? null : (nextDueDate ?? this.nextDueDate),
      nextDueOdometer: clearNextOdometer ? null : (nextDueOdometer ?? this.nextDueOdometer),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'title': title,
        'notes': notes,
        'trigger_type': triggerType.name,
        'due_date': dueDate?.millisecondsSinceEpoch,
        'due_odometer': dueOdometer,
        'notify_before_days': notifyBeforeDays,
        'notify_before_km': notifyBeforeKm,
        'is_completed': isCompleted ? 1 : 0,
        'completed_date': completedDate?.millisecondsSinceEpoch,
        'next_due_date': nextDueDate?.millisecondsSinceEpoch,
        'next_due_odometer': nextDueOdometer,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ServiceRecord.fromMap(Map<String, dynamic> map) => ServiceRecord(
        id: map['id'] as int?,
        vehicleId: map['vehicle_id'] as int,
        title: map['title'] as String,
        notes: map['notes'] as String?,
        triggerType: ServiceTriggerType.fromString(map['trigger_type'] as String),
        dueDate: map['due_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
            : null,
        dueOdometer: map['due_odometer'] != null
            ? (map['due_odometer'] as num).toDouble()
            : null,
        notifyBeforeDays: map['notify_before_days'] as int? ?? 7,
        notifyBeforeKm: map['notify_before_km'] != null
            ? (map['notify_before_km'] as num).toDouble()
            : null,
        isCompleted: (map['is_completed'] as int? ?? 0) == 1,
        completedDate: map['completed_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['completed_date'] as int)
            : null,
        nextDueDate: map['next_due_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['next_due_date'] as int)
            : null,
        nextDueOdometer: map['next_due_odometer'] != null
            ? (map['next_due_odometer'] as num).toDouble()
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
