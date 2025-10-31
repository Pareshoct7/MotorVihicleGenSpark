import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 0)
class Vehicle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String registrationNo;

  @HiveField(2)
  String? make;

  @HiveField(3)
  String? model;

  @HiveField(4)
  int? year;

  @HiveField(5)
  DateTime? wofExpiryDate;

  @HiveField(6)
  DateTime? regoExpiryDate;

  @HiveField(7)
  String? storeId;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.registrationNo,
    this.make,
    this.model,
    this.year,
    this.wofExpiryDate,
    this.regoExpiryDate,
    this.storeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isWofExpiringSoon {
    if (wofExpiryDate == null) return false;
    final daysUntilExpiry = wofExpiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isWofExpired {
    if (wofExpiryDate == null) return false;
    return wofExpiryDate!.isBefore(DateTime.now());
  }

  bool get isRegoExpiringSoon {
    if (regoExpiryDate == null) return false;
    final daysUntilExpiry = regoExpiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isRegoExpired {
    if (regoExpiryDate == null) return false;
    return regoExpiryDate!.isBefore(DateTime.now());
  }
}
