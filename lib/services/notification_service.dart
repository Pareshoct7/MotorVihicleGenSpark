import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/vehicle.dart';
import '../models/notification_settings.dart';
import '../services/database_service.dart';

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
    return id.hashCode.abs();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      print('ERROR: Failed to schedule notification $id: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllRemindersForVehicle(String vehicleId) async {
    // We can't query all scheduled notifications by tag easily in this plugin without keeping track of IDs.
    // However, since our IDs are deterministic based on vehicleId + type + interval,
    // we can attempt to cancel probable IDs. For now, rely on overwriting as we reschedule.
    // A better approach would be to store scheduled IDs in Hive, but for this scope, rescheduling is sufficient
    // as it will overwrite existing alarms for the same ID.
    
    // For safety, let's try to cancel the "old style" single IDs first
    await cancelNotification(_generateId('${vehicleId}_wof'));
    await cancelNotification(_generateId('${vehicleId}_rego'));
    
    // And cancel potential multi-day IDs
    final intervals = [30, 14, 7, 3, 1, 0];
    for (final days in intervals) {
       await cancelNotification(_generateId('${vehicleId}_wof_$days'));
       await cancelNotification(_generateId('${vehicleId}_rego_$days'));
       await cancelNotification(_generateId('${vehicleId}_service_$days'));
       await cancelNotification(_generateId('${vehicleId}_tyre_$days'));
    }
  }

  Future<void> scheduleWofReminder(
      Vehicle vehicle, NotificationSettings settings) async {
    if (!settings.wofNotificationsEnabled || vehicle.wofExpiryDate == null) {
      final intervals = [30, 14, 7, 3, 1, 0];
      for (final days in intervals) {
         await cancelNotification(_generateId('${vehicle.id}_wof_$days'));
      }
      return;
    }

    final intervals = [30, 14, 7, 3, 1, 0];
    
    for (final days in intervals) {
      if (settings.wofDaysBefore < days && days != 0) continue; 
      
      final scheduledDate = vehicle.wofExpiryDate!.subtract(Duration(days: days));
      final notificationId = _generateId('${vehicle.id}_wof_$days');

      if (scheduledDate.isAfter(DateTime.now())) {
         await scheduleNotification(
          id: notificationId,
          title: 'WOF Expiry Reminder',
          body: days == 0 
              ? 'WOF for ${vehicle.registrationNo} expires TODAY!' 
              : 'WOF for ${vehicle.registrationNo} expires in $days days (${_formatDate(vehicle.wofExpiryDate!)})',
          scheduledDate: scheduledDate,
          payload: 'wof_reminder',
        );
      }
    }
  }

  Future<void> scheduleRegoReminder(
      Vehicle vehicle, NotificationSettings settings) async {

    if (!settings.regoNotificationsEnabled || vehicle.regoExpiryDate == null) {
      final intervals = [30, 14, 7, 3, 1, 0];
      for (final days in intervals) {
         await cancelNotification(_generateId('${vehicle.id}_rego_$days'));
      }
      return;
    }

    final intervals = [30, 14, 7, 3, 1, 0];

    for (final days in intervals) {
      final scheduledDate = vehicle.regoExpiryDate!.subtract(Duration(days: days));
      final notificationId = _generateId('${vehicle.id}_rego_$days');

      if (scheduledDate.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: notificationId,
          title: 'Rego Expiry Reminder',
          body: days == 0 
              ? 'Registration for ${vehicle.registrationNo} expires TODAY!' 
              : 'Registration for ${vehicle.registrationNo} expires in $days days (${_formatDate(vehicle.regoExpiryDate!)})',
          scheduledDate: scheduledDate,
          payload: 'rego_reminder',
        );
      }
    }
  }

  Future<void> scheduleServiceReminder(
      Vehicle vehicle, NotificationSettings settings) async {

    if (!settings.serviceNotificationsEnabled || vehicle.serviceDueDate == null) {
      final intervals = [30, 14, 7, 3, 1, 0];
      for (final days in intervals) {
         await cancelNotification(_generateId('${vehicle.id}_service_$days'));
      }
      return;
    }

    final intervals = [30, 14, 7, 3, 1, 0];

    for (final days in intervals) {
      final scheduledDate = vehicle.serviceDueDate!.subtract(Duration(days: days));
      final notificationId = _generateId('${vehicle.id}_service_$days');

      if (scheduledDate.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: notificationId,
          title: 'Service Due Reminder',
          body: days == 0 
              ? 'Service for ${vehicle.registrationNo} is due TODAY!' 
              : 'Service for ${vehicle.registrationNo} is due in $days days (${_formatDate(vehicle.serviceDueDate!)})',
          scheduledDate: scheduledDate,
          payload: 'service_reminder',
        );
      }
    }
  }

  Future<void> scheduleTyreCheckReminder(
      Vehicle vehicle, NotificationSettings settings) async {

    if (!settings.tyreNotificationsEnabled || vehicle.tyreCheckDate == null) {
      final intervals = [30, 14, 7, 3, 1, 0];
      for (final days in intervals) {
         await cancelNotification(_generateId('${vehicle.id}_tyre_$days'));
      }
      return;
    }

    final intervals = [30, 14, 7, 3, 1, 0];

    for (final days in intervals) {
      final scheduledDate = vehicle.tyreCheckDate!.subtract(Duration(days: days));
      final notificationId = _generateId('${vehicle.id}_tyre_$days');

      if (scheduledDate.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: notificationId,
          title: 'Tyre Check Reminder',
          body: days == 0 
              ? 'Tyre Check for ${vehicle.registrationNo} is due TODAY!' 
              : 'Tyre Check for ${vehicle.registrationNo} due in $days days (${_formatDate(vehicle.tyreCheckDate!)})',
          scheduledDate: scheduledDate,
          payload: 'tyre_reminder',
        );
      }
    }
  }
  
  Future<void> rescheduleAllNotifications() async {
    // Load all vehicles
    final vehicles = DatabaseService.getAllVehicles();
    
    for (final vehicle in vehicles) {
       final settings = DatabaseService.getOrCreateNotificationSettings(vehicle.id);
       await scheduleWofReminder(vehicle, settings);
       await scheduleRegoReminder(vehicle, settings);
       await scheduleServiceReminder(vehicle, settings);
       await scheduleTyreCheckReminder(vehicle, settings);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
