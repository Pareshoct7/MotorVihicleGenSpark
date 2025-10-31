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
      wofNotificationsEnabled: fields[2] as bool,
      wofDaysBefore: fields[3] as int,
      regoNotificationsEnabled: fields[4] as bool,
      regoDaysBefore: fields[5] as int,
      customWofNotificationDate: fields[6] as DateTime?,
      customRegoNotificationDate: fields[7] as DateTime?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.wofNotificationsEnabled)
      ..writeByte(3)
      ..write(obj.wofDaysBefore)
      ..writeByte(4)
      ..write(obj.regoNotificationsEnabled)
      ..writeByte(5)
      ..write(obj.regoDaysBefore)
      ..writeByte(6)
      ..write(obj.customWofNotificationDate)
      ..writeByte(7)
      ..write(obj.customRegoNotificationDate)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
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
