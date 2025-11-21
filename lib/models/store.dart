import 'package:hive/hive.dart';

part 'store.g.dart';

@HiveType(typeId: 1)
class Store extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? address;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String? storeNumber;

  Store({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.storeNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Get display name with store number in brackets
  String get displayName {
    if (storeNumber != null && storeNumber!.isNotEmpty) {
      return '$name ($storeNumber)';
    }
    return name;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'storeNumber': storeNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      storeNumber: json['storeNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
