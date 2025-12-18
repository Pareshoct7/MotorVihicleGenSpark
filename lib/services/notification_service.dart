import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/vehicle.dart';
import '../models/notification_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  // Handler for when a notification is tapped
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap
  }

  // Handler for foreground notifications on iOS
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    // Display a dialog or handle the notification
  }

  // Calculate a unique integer ID from a string
  int _generateId(String id) {
    return id.hashCode.abs(); // Simple hash for demo; consider a more robust mapping for production
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vehicle_reminders',
          'Vehicle Reminders',
          channelDescription: 'Reminders for WOF and Registration expiry',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> scheduleWofReminder(
      Vehicle vehicle, NotificationSettings settings) async {
    // Note: vehicle is of type Vehicle, settings is NotificationSettings
    
    final int notificationId = _generateId('${vehicle.id}_wof');

    if (!settings.wofNotificationsEnabled || vehicle.wofExpiryDate == null) {
      await cancelNotification(notificationId);
      return;
    }

    DateTime? scheduledDate;

    if (settings.customWofNotificationDate != null) {
      scheduledDate = settings.customWofNotificationDate;
    } else {
      // Calculate based on days before
      scheduledDate = vehicle.wofExpiryDate!
          .subtract(Duration(days: settings.wofDaysBefore));
    }

    // Ensure scheduled date is in the future
    if (scheduledDate != null && scheduledDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId,
        title: 'WOF Expiry Reminder',
        body: 'WOF for ${vehicle.registrationNo} expires on ${_formatDate(vehicle.wofExpiryDate!)}',
        scheduledDate: scheduledDate,
        payload: 'wof_reminder',
      );
    }
  }

  Future<void> scheduleRegoReminder(
      Vehicle vehicle, NotificationSettings settings) async {
    final int notificationId = _generateId('${vehicle.id}_rego');

    if (!settings.regoNotificationsEnabled || vehicle.regoExpiryDate == null) {
      await cancelNotification(notificationId);
      return;
    }

    DateTime? scheduledDate;

    if (settings.customRegoNotificationDate != null) {
      scheduledDate = settings.customRegoNotificationDate;
    } else {
      scheduledDate = vehicle.regoExpiryDate!
          .subtract(Duration(days: settings.regoDaysBefore));
    }

    if (scheduledDate != null && scheduledDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId,
        title: 'Rego Expiry Reminder',
        body: 'Registration for ${vehicle.registrationNo} expires on ${_formatDate(vehicle.regoExpiryDate!)}',
        scheduledDate: scheduledDate,
        payload: 'rego_reminder',
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
