// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomReminderAdapter extends TypeAdapter<CustomReminder> {
  @override
  final int typeId = 6;

  @override
  CustomReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomReminder(
      id: fields[0] as String,
      days: fields[1] as int,
      hours: fields[2] as int,
      minutes: fields[3] as int,
      repeat: fields[4] as RepeatInterval,
    );
  }

  @override
  void write(BinaryWriter writer, CustomReminder obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.days)
      ..writeByte(2)
      ..write(obj.hours)
      ..writeByte(3)
      ..write(obj.minutes)
      ..writeByte(4)
      ..write(obj.repeat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RepeatIntervalAdapter extends TypeAdapter<RepeatInterval> {
  @override
  final int typeId = 5;

  @override
  RepeatInterval read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatInterval.none;
      case 1:
        return RepeatInterval.hourly;
      case 2:
        return RepeatInterval.daily;
      default:
        return RepeatInterval.none;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatInterval obj) {
    switch (obj) {
      case RepeatInterval.none:
        writer.writeByte(0);
        break;
      case RepeatInterval.hourly:
        writer.writeByte(1);
        break;
      case RepeatInterval.daily:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatIntervalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
