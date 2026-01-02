import 'package:hive/hive.dart';
import 'custom_reminder.dart';

part 'notification_settings.g.dart';

@HiveType(typeId: 4)
class NotificationSettings extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  // Legacy fields - kept for structure but new logic uses fields below
  @HiveField(2)
  bool wofDefaultReminder;

  @HiveField(3)
  bool regoDefaultReminder;

  @HiveField(4)
  List<CustomReminder> wofCustomReminders;

  @HiveField(5)
  List<CustomReminder> regoCustomReminders;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  // New fields for simplified notification logic
  @HiveField(8)
  bool wofNotificationsEnabled;

  @HiveField(9)
  int wofDaysBefore;

  @HiveField(10)
  DateTime? customWofNotificationDate;

  @HiveField(11)
  bool regoNotificationsEnabled;

  @HiveField(12)
  int regoDaysBefore;

  @HiveField(13)
  DateTime? customRegoNotificationDate;

  @HiveField(14)
  bool serviceNotificationsEnabled;

  @HiveField(15)
  int serviceDaysBefore;

  @HiveField(16)
  DateTime? customServiceNotificationDate;

  @HiveField(17)
  bool tyreNotificationsEnabled;

  @HiveField(18)
  int tyreDaysBefore;

  @HiveField(19)
  DateTime? customTyreNotificationDate;

  NotificationSettings({
    required this.id,
    required this.vehicleId,
    this.wofDefaultReminder = true,
    this.regoDefaultReminder = true,
    List<CustomReminder>? wofCustomReminders,
    List<CustomReminder>? regoCustomReminders,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? wofNotificationsEnabled,
    int? wofDaysBefore,
    this.customWofNotificationDate,
    bool? regoNotificationsEnabled,
    int? regoDaysBefore,
    this.customRegoNotificationDate,
    bool? serviceNotificationsEnabled,
    int? serviceDaysBefore,
    this.customServiceNotificationDate,
    bool? tyreNotificationsEnabled,
    int? tyreDaysBefore,
    this.customTyreNotificationDate,
  })  : wofCustomReminders = wofCustomReminders ?? [],
        regoCustomReminders = regoCustomReminders ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        wofNotificationsEnabled = wofNotificationsEnabled ?? wofDefaultReminder,
        wofDaysBefore = wofDaysBefore ?? 1,
        regoNotificationsEnabled = regoNotificationsEnabled ?? regoDefaultReminder,
        regoDaysBefore = regoDaysBefore ?? 1,
        serviceNotificationsEnabled = serviceNotificationsEnabled ?? true,
        serviceDaysBefore = serviceDaysBefore ?? 1,
        tyreNotificationsEnabled = tyreNotificationsEnabled ?? true,
        tyreDaysBefore = tyreDaysBefore ?? 1;
}
