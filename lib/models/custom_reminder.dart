import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'custom_reminder.g.dart';

@HiveType(typeId: 5)
enum RepeatInterval {
  @HiveField(0)
  none,

  @HiveField(1)
  hourly,

  @HiveField(2)
  daily,
}

@HiveType(typeId: 6)
class CustomReminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int days;

  @HiveField(2)
  int hours;

  @HiveField(3)
  int minutes;

  @HiveField(4)
  RepeatInterval repeat;

  CustomReminder({
    required this.id,
    this.days = 0,
    this.hours = 9,
    this.minutes = 0,
    this.repeat = RepeatInterval.none,
  });

  TimeOfDay get time => TimeOfDay(hour: hours, minute: minutes);
}
