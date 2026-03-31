import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:study_app/models/event.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _plugin.initialize(
        initSettings, 
        onDidReceiveNotificationResponse: (NotificationResponse response) async {}
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  Future<void> scheduleEventNotification(Event event) async {
    if (!_initialized) return;
    final int baseId = event.id.hashCode;

    // Check permissions on iOS dynamically
    _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);

    try {
      // 1 Day Before
      final tz.TZDateTime dayBefore = tz.TZDateTime.from(event.date.subtract(const Duration(days: 1)), tz.local);
      if (dayBefore.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          baseId,
          'Upcoming Event: ${event.title}',
          'Your event is exactly 1 day away!',
          dayBefore,
          const NotificationDetails(
            android: AndroidNotificationDetails('events_channel', 'Events', importance: Importance.max, priority: Priority.high),
          ),
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      // 1 Hour Before
      final tz.TZDateTime hourBefore = tz.TZDateTime.from(event.date.subtract(const Duration(hours: 1)), tz.local);
      if (hourBefore.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          baseId + 1,
          'Starting Soon: ${event.title}',
          'Your event starts in 1 hour!',
          hourBefore,
          const NotificationDetails(
            android: AndroidNotificationDetails('events_channel', 'Events', importance: Importance.max, priority: Priority.high),
          ),
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotifications(String eventId) async {
    try {
      final int baseId = eventId.hashCode;
      await _plugin.cancel(baseId);
      await _plugin.cancel(baseId + 1);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}
