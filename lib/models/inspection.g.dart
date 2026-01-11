// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InspectionAdapter extends TypeAdapter<Inspection> {
  @override
  final int typeId = 3;

  @override
  Inspection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Inspection(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      storeId: fields[2] as String?,
      driverId: fields[3] as String?,
      inspectionDate: fields[4] as DateTime,
      odometerReading: fields[5] as String,
      vehicleRegistrationNo: fields[6] as String,
      storeName: fields[7] as String,
      employeeName: fields[8] as String,
      storeNumber: fields[35] as String?,
      tyresTreadDepth: fields[9] as bool?,
      wheelNuts: fields[10] as bool?,
      cleanliness: fields[11] as bool?,
      bodyDamage: fields[12] as bool?,
      bodyDamageNotes: fields[13] as String?,
      mirrorsWindows: fields[14] as bool?,
      signage: fields[15] as bool?,
      engineOilWater: fields[16] as bool?,
      brakes: fields[17] as bool?,
      transmission: fields[18] as bool?,
      tailLights: fields[19] as bool?,
      headlightsLowBeam: fields[20] as bool?,
      headlightsHighBeam: fields[21] as bool?,
      reverseLights: fields[22] as bool?,
      brakeLights: fields[23] as bool?,
      windscreenWipers: fields[24] as bool?,
      horn: fields[25] as bool?,
      indicators: fields[26] as bool?,
      seatBelts: fields[27] as bool?,
      cabCleanliness: fields[28] as bool?,
      serviceLogBook: fields[29] as bool?,
      spareKeys: fields[30] as bool?,
      correctiveActions: fields[31] as String?,
      signature: fields[32] as String?,
      managerSignature: fields[36] as String?,
      managerSignOffDate: fields[37] as DateTime?,
      createdAt: fields[33] as DateTime?,
      updatedAt: fields[34] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Inspection obj) {
    writer
      ..writeByte(38)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.storeId)
      ..writeByte(3)
      ..write(obj.driverId)
      ..writeByte(4)
      ..write(obj.inspectionDate)
      ..writeByte(5)
      ..write(obj.odometerReading)
      ..writeByte(6)
      ..write(obj.vehicleRegistrationNo)
      ..writeByte(7)
      ..write(obj.storeName)
      ..writeByte(8)
      ..write(obj.employeeName)
      ..writeByte(9)
      ..write(obj.tyresTreadDepth)
      ..writeByte(10)
      ..write(obj.wheelNuts)
      ..writeByte(11)
      ..write(obj.cleanliness)
      ..writeByte(12)
      ..write(obj.bodyDamage)
      ..writeByte(13)
      ..write(obj.bodyDamageNotes)
      ..writeByte(14)
      ..write(obj.mirrorsWindows)
      ..writeByte(15)
      ..write(obj.signage)
      ..writeByte(16)
      ..write(obj.engineOilWater)
      ..writeByte(17)
      ..write(obj.brakes)
      ..writeByte(18)
      ..write(obj.transmission)
      ..writeByte(19)
      ..write(obj.tailLights)
      ..writeByte(20)
      ..write(obj.headlightsLowBeam)
      ..writeByte(21)
      ..write(obj.headlightsHighBeam)
      ..writeByte(22)
      ..write(obj.reverseLights)
      ..writeByte(23)
      ..write(obj.brakeLights)
      ..writeByte(24)
      ..write(obj.windscreenWipers)
      ..writeByte(25)
      ..write(obj.horn)
      ..writeByte(26)
      ..write(obj.indicators)
      ..writeByte(27)
      ..write(obj.seatBelts)
      ..writeByte(28)
      ..write(obj.cabCleanliness)
      ..writeByte(29)
      ..write(obj.serviceLogBook)
      ..writeByte(30)
      ..write(obj.spareKeys)
      ..writeByte(31)
      ..write(obj.correctiveActions)
      ..writeByte(32)
      ..write(obj.signature)
      ..writeByte(33)
      ..write(obj.createdAt)
      ..writeByte(34)
      ..write(obj.updatedAt)
      ..writeByte(35)
      ..write(obj.storeNumber)
      ..writeByte(36)
      ..write(obj.managerSignature)
      ..writeByte(37)
      ..write(obj.managerSignOffDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
