// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 0;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      id: fields[0] as String,
      registrationNo: fields[1] as String,
      make: fields[2] as String?,
      model: fields[3] as String?,
      year: fields[4] as int?,
      wofExpiryDate: fields[5] as DateTime?,
      regoExpiryDate: fields[6] as DateTime?,
      storeId: fields[7] as String?,
      serviceDueDate: fields[10] as DateTime?,
      tyreCheckDate: fields[11] as DateTime?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.registrationNo)
      ..writeByte(2)
      ..write(obj.make)
      ..writeByte(3)
      ..write(obj.model)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.wofExpiryDate)
      ..writeByte(6)
      ..write(obj.regoExpiryDate)
      ..writeByte(7)
      ..write(obj.storeId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.serviceDueDate)
      ..writeByte(11)
      ..write(obj.tyreCheckDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
