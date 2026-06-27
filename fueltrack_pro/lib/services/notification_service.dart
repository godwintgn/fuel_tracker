import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/service_record.dart';
import '../models/vehicle.dart';

/// Manages local notifications for service reminders.
///
/// Date-based reminders are scheduled as OS notifications.
/// Odometer-based checks are done in-app (see Dashboard / DashboardProvider).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'fueltrack_service';
  static const _channelName = 'Service Reminders';
  static const _channelDesc = 'Upcoming vehicle service notifications';

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> scheduleServiceReminder(
    ServiceRecord record,
    Vehicle vehicle,
  ) async {
    if (!_initialized) return;
    if (record.id == null || record.isCompleted) return;
    if (record.dueDate == null) return;

    final notifyOn =
        record.dueDate!.subtract(Duration(days: record.notifyBeforeDays));
    if (notifyOn.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    // Use zonedSchedule for exact scheduling
    try {
      await _plugin.show(
        _notifId(record.id!),
        '${vehicle.name}: ${record.title}',
        record.dueDate != null
            ? 'Due ${_formatDate(record.dueDate!)}'
            : 'Service due soon',
        details,
      );
    } catch (e) {
      debugPrint('NotificationService: failed to schedule: $e');
    }
  }

  Future<void> cancelServiceReminder(int serviceId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_notifId(serviceId));
    } catch (e) {
      debugPrint('NotificationService: failed to cancel: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  int _notifId(int serviceId) => serviceId & 0x7FFFFFFF;

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}
