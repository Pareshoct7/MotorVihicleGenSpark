import 'package:hive/hive.dart';

part 'inspection.g.dart';

@HiveType(typeId: 3)
class Inspection extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  String? storeId;

  @HiveField(3)
  String? driverId;

  @HiveField(4)
  DateTime inspectionDate;

  @HiveField(5)
  String odometerReading;

  @HiveField(6)
  String vehicleRegistrationNo;

  @HiveField(7)
  String storeName;

  @HiveField(8)
  String employeeName;

  // Tyres checklist
  @HiveField(9)
  bool? tyresTreadDepth;

  @HiveField(10)
  bool? wheelNuts;

  // Outside checklist
  @HiveField(11)
  bool? cleanliness;

  @HiveField(12)
  bool? bodyDamage;

  @HiveField(13)
  String? bodyDamageNotes;

  @HiveField(14)
  bool? mirrorsWindows;

  @HiveField(15)
  bool? signage;

  // Mechanical checklist
  @HiveField(16)
  bool? engineOilWater;

  @HiveField(17)
  bool? brakes;

  @HiveField(18)
  bool? transmission;

  // Electrical checklist
  @HiveField(19)
  bool? tailLights;

  @HiveField(20)
  bool? headlightsLowBeam;

  @HiveField(21)
  bool? headlightsHighBeam;

  @HiveField(22)
  bool? reverseLights;

  @HiveField(23)
  bool? brakeLights;

  // Cab checklist
  @HiveField(24)
  bool? windscreenWipers;

  @HiveField(25)
  bool? horn;

  @HiveField(26)
  bool? indicators;

  @HiveField(27)
  bool? seatBelts;

  @HiveField(28)
  bool? cabCleanliness;

  @HiveField(29)
  bool? serviceLogBook;

  @HiveField(30)
  bool? spareKeys;

  // Additional fields
  @HiveField(31)
  String? correctiveActions;

  @HiveField(32)
  String? signature;

  @HiveField(33)
  DateTime createdAt;

  @HiveField(34)
  DateTime updatedAt;

  @HiveField(35)
  String? storeNumber;

  Inspection({
    required this.id,
    required this.vehicleId,
    this.storeId,
    this.driverId,
    required this.inspectionDate,
    required this.odometerReading,
    required this.vehicleRegistrationNo,
    required this.storeName,
    required this.employeeName,
    this.storeNumber,
    this.tyresTreadDepth,
    this.wheelNuts,
    this.cleanliness,
    this.bodyDamage,
    this.bodyDamageNotes,
    this.mirrorsWindows,
    this.signage,
    this.engineOilWater,
    this.brakes,
    this.transmission,
    this.tailLights,
    this.headlightsLowBeam,
    this.headlightsHighBeam,
    this.reverseLights,
    this.brakeLights,
    this.windscreenWipers,
    this.horn,
    this.indicators,
    this.seatBelts,
    this.cabCleanliness,
    this.serviceLogBook,
    this.spareKeys,
    this.correctiveActions,
    this.signature,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'storeId': storeId,
      'driverId': driverId,
      'inspectionDate': inspectionDate.toIso8601String(),
      'odometerReading': odometerReading,
      'vehicleRegistrationNo': vehicleRegistrationNo,
      'storeName': storeName,
      'storeNumber': storeNumber,
      'employeeName': employeeName,
      'tyresTreadDepth': tyresTreadDepth,
      'wheelNuts': wheelNuts,
      'cleanliness': cleanliness,
      'bodyDamage': bodyDamage,
      'bodyDamageNotes': bodyDamageNotes,
      'mirrorsWindows': mirrorsWindows,
      'signage': signage,
      'engineOilWater': engineOilWater,
      'brakes': brakes,
      'transmission': transmission,
      'tailLights': tailLights,
      'headlightsLowBeam': headlightsLowBeam,
      'headlightsHighBeam': headlightsHighBeam,
      'reverseLights': reverseLights,
      'brakeLights': brakeLights,
      'windscreenWipers': windscreenWipers,
      'horn': horn,
      'indicators': indicators,
      'seatBelts': seatBelts,
      'cabCleanliness': cabCleanliness,
      'serviceLogBook': serviceLogBook,
      'spareKeys': spareKeys,
      'correctiveActions': correctiveActions,
      'signature': signature,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'],
      vehicleId: json['vehicleId'],
      storeId: json['storeId'],
      driverId: json['driverId'],
      inspectionDate: DateTime.parse(json['inspectionDate']),
      odometerReading: json['odometerReading'],
      vehicleRegistrationNo: json['vehicleRegistrationNo'],
      storeName: json['storeName'],
      storeNumber: json['storeNumber'],
      employeeName: json['employeeName'],
      tyresTreadDepth: json['tyresTreadDepth'],
      wheelNuts: json['wheelNuts'],
      cleanliness: json['cleanliness'],
      bodyDamage: json['bodyDamage'],
      bodyDamageNotes: json['bodyDamageNotes'],
      mirrorsWindows: json['mirrorsWindows'],
      signage: json['signage'],
      engineOilWater: json['engineOilWater'],
      brakes: json['brakes'],
      transmission: json['transmission'],
      tailLights: json['tailLights'],
      headlightsLowBeam: json['headlightsLowBeam'],
      headlightsHighBeam: json['headlightsHighBeam'],
      reverseLights: json['reverseLights'],
      brakeLights: json['brakeLights'],
      windscreenWipers: json['windscreenWipers'],
      horn: json['horn'],
      indicators: json['indicators'],
      seatBelts: json['seatBelts'],
      cabCleanliness: json['cabCleanliness'],
      serviceLogBook: json['serviceLogBook'],
      spareKeys: json['spareKeys'],
      correctiveActions: json['correctiveActions'],
      signature: json['signature'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  int get completedItems {
    int count = 0;
    if (tyresTreadDepth == true) count++;
    if (wheelNuts == true) count++;
    if (cleanliness == true) count++;
    if (bodyDamage == true) count++;
    if (mirrorsWindows == true) count++;
    if (signage == true) count++;
    if (engineOilWater == true) count++;
    if (brakes == true) count++;
    if (transmission == true) count++;
    if (tailLights == true) count++;
    if (headlightsLowBeam == true) count++;
    if (headlightsHighBeam == true) count++;
    if (reverseLights == true) count++;
    if (brakeLights == true) count++;
    if (windscreenWipers == true) count++;
    if (horn == true) count++;
    if (indicators == true) count++;
    if (seatBelts == true) count++;
    if (cabCleanliness == true) count++;
    if (serviceLogBook == true) count++;
    if (spareKeys == true) count++;
    return count;
  }

  int get totalItems => 21;

  double get completionPercentage {
    return (completedItems / totalItems) * 100;
  }

  /// Get store display name with number in brackets
  String get storeDisplayName {
    if (storeNumber != null && storeNumber!.isNotEmpty) {
      return '$storeName ($storeNumber)';
    }
    return storeName;
  }
}
