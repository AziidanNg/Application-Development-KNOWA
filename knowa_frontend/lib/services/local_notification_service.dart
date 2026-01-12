// lib/services/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Request permissions for iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  // --- 1. SHOW INSTANT NOTIFICATION (For Testing) ---
  // You need this for the "Push Notifications" toggle in Settings
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'knowa_alerts', 
      'General Alerts',
      channelDescription: 'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, details);
  }

  // --- 2. SCHEDULE A SINGLE EVENT (For Event Reminders) ---
  static Future<void> scheduleEventReminder({
    required int id,
    required String title,
    required String body,
    required DateTime eventTime,
    required Duration offset,
  }) async {
    final scheduledDate = eventTime.subtract(offset);
    final now = DateTime.now();

    // Only schedule if the reminder time hasn't passed yet
    if (scheduledDate.isBefore(now)) return;

    await _notificationsPlugin.zonedSchedule(
      id, // Unique ID (use Event ID)
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'knowa_events',
          'Event Reminders',
          channelDescription: 'Reminders for joined events',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // --- 3. CANCEL ALL (Use this when turning setting OFF) ---
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}