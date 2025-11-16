import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);
      
    } catch (e) {
      Text('Error initializing notifications: $e');
    }
  }

  static Future<void> scheduleTaskReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int id,
  }) async {
    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminder_channel',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      
    } catch (e) {
      Text('Error scheduling task reminder: $e');
    }
  }

  static Future<void> scheduleTaskDueNotification({
    required String taskTitle,
    required DateTime dueTime,
    required int taskId,
  }) async {
    try {
      final reminderTime = dueTime.subtract(const Duration(minutes: 15));
      final tzScheduledTime = tz.TZDateTime.from(reminderTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_due_channel',
        'Task Due Reminders',
        channelDescription: 'Notifications for upcoming task deadlines',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        taskId,
        'Task Due Soon: $taskTitle',
        'Your task is due in 15 minutes!',
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      
    } catch (e) {
      Text('Error scheduling task due notification: $e');
    }
  }

  static Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required TimeOfDay time,
    required int id,
  }) async {
    try {
      final now = DateTime.now();
      final scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      final scheduledTime = scheduled.isBefore(now) 
          ? scheduled.add(const Duration(days: 1))
          : scheduled;

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'Daily Reminders',
        channelDescription: 'Daily task reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      
    } catch (e) {
      Text('Error scheduling daily reminder: $e');
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'instant_notification_channel',
        'Instant Notifications',
        channelDescription: 'Instant notifications for important updates',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details);
    } catch (e) {
      Text('Error showing instant notification: $e');
    }
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      Text('Error getting pending notifications: $e');
      return [];
    }
  }

  static Future<bool> isNotificationScheduled(int id) async {
    try {
      final pending = await getPendingNotifications();
      return pending.any((notification) => notification.id == id);
    } catch (e) {
      Text('Error checking if notification is scheduled: $e');
      return false;
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      Text('Error cancelling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      Text('Error cancelling all notifications: $e');
    }
  }
}