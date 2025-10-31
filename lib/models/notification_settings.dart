import 'package:hive/hive.dart';

part 'notification_settings.g.dart';

@HiveType(typeId: 4)
class NotificationSettings extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  bool wofNotificationsEnabled;

  @HiveField(3)
  int wofDaysBefore;

  @HiveField(4)
  bool regoNotificationsEnabled;

  @HiveField(5)
  int regoDaysBefore;

  @HiveField(6)
  DateTime? customWofNotificationDate;

  @HiveField(7)
  DateTime? customRegoNotificationDate;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  NotificationSettings({
    required this.id,
    required this.vehicleId,
    this.wofNotificationsEnabled = true,
    this.wofDaysBefore = 30,
    this.regoNotificationsEnabled = true,
    this.regoDaysBefore = 30,
    this.customWofNotificationDate,
    this.customRegoNotificationDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
