// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 4;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      wofDefaultReminder: fields[2] as bool,
      regoDefaultReminder: fields[3] as bool,
      wofCustomReminders: (fields[4] as List?)?.cast<CustomReminder>(),
      regoCustomReminders: (fields[5] as List?)?.cast<CustomReminder>(),
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      wofNotificationsEnabled: fields[8] as bool?,
      wofDaysBefore: fields[9] as int?,
      customWofNotificationDate: fields[10] as DateTime?,
      regoNotificationsEnabled: fields[11] as bool?,
      regoDaysBefore: fields[12] as int?,
      customRegoNotificationDate: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.wofDefaultReminder)
      ..writeByte(3)
      ..write(obj.regoDefaultReminder)
      ..writeByte(4)
      ..write(obj.wofCustomReminders)
      ..writeByte(5)
      ..write(obj.regoCustomReminders)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.wofNotificationsEnabled)
      ..writeByte(9)
      ..write(obj.wofDaysBefore)
      ..writeByte(10)
      ..write(obj.customWofNotificationDate)
      ..writeByte(11)
      ..write(obj.regoNotificationsEnabled)
      ..writeByte(12)
      ..write(obj.regoDaysBefore)
      ..writeByte(13)
      ..write(obj.customRegoNotificationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
