import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle.dart';
import '../models/store.dart';
import '../models/driver.dart';
import '../models/inspection.dart';
import '../models/notification_settings.dart';
import 'ai_learning_service.dart';

class DatabaseService {
  static const String vehiclesBox = 'vehicles';
  static const String storesBox = 'stores';
  static const String driversBox = 'drivers';
  static const String inspectionsBox = 'inspections';
  static const String notificationSettingsBox = 'notification_settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(StoreAdapter());
    Hive.registerAdapter(DriverAdapter());
    Hive.registerAdapter(InspectionAdapter());
    Hive.registerAdapter(NotificationSettingsAdapter());

    // Open boxes
    await Hive.openBox<Vehicle>(vehiclesBox);
    await Hive.openBox<Store>(storesBox);
    await Hive.openBox<Driver>(driversBox);
    await Hive.openBox<Inspection>(inspectionsBox);
    await Hive.openBox<NotificationSettings>(notificationSettingsBox);
    
    // Initialize AI Learning Service
    await AILearningService.init();
  }

  // Vehicle operations
  static Box<Vehicle> getVehiclesBox() => Hive.box<Vehicle>(vehiclesBox);

  static Future<void> addVehicle(Vehicle vehicle) async {
    final box = getVehiclesBox();
    await box.put(vehicle.id, vehicle);
  }

  static Future<void> updateVehicle(Vehicle vehicle) async {
    final box = getVehiclesBox();
    await box.put(vehicle.id, vehicle);
  }

  static Future<void> deleteVehicle(String id) async {
    final box = getVehiclesBox();
    await box.delete(id);
  }

  static Vehicle? getVehicle(String id) {
    final box = getVehiclesBox();
    return box.get(id);
  }

  static List<Vehicle> getAllVehicles() {
    final box = getVehiclesBox();
    return box.values.toList();
  }

  static List<Vehicle> getVehiclesByStore(String storeId) {
    final box = getVehiclesBox();
    return box.values.where((v) => v.storeId == storeId).toList();
  }

  // Store operations
  static Box<Store> getStoresBox() => Hive.box<Store>(storesBox);

  static Future<void> addStore(Store store) async {
    final box = getStoresBox();
    await box.put(store.id, store);
  }

  static Future<void> updateStore(Store store) async {
    final updatedStore = Store(
      id: store.id,
      name: store.name,
      address: store.address,
      phone: store.phone,
      createdAt: store.createdAt,
      updatedAt: DateTime.now(),
    );
    await addStore(updatedStore);
  }

  static Future<void> deleteStore(String id) async {
    final box = getStoresBox();
    await box.delete(id);
  }

  static Store? getStore(String id) {
    final box = getStoresBox();
    return box.get(id);
  }

  static List<Store> getAllStores() {
    final box = getStoresBox();
    return box.values.toList();
  }

  // Driver operations
  static Box<Driver> getDriversBox() => Hive.box<Driver>(driversBox);

  static Future<void> addDriver(Driver driver) async {
    final box = getDriversBox();
    await box.put(driver.id, driver);
  }

  static Future<void> updateDriver(Driver driver) async {
    final updatedDriver = Driver(
      id: driver.id,
      name: driver.name,
      licenseNumber: driver.licenseNumber,
      phone: driver.phone,
      email: driver.email,
      createdAt: driver.createdAt,
      updatedAt: DateTime.now(),
    );
    await addDriver(updatedDriver);
  }

  static Future<void> deleteDriver(String id) async {
    final box = getDriversBox();
    await box.delete(id);
  }

  static Driver? getDriver(String id) {
    final box = getDriversBox();
    return box.get(id);
  }

  static List<Driver> getAllDrivers() {
    final box = getDriversBox();
    return box.values.toList();
  }

  // Inspection operations
  static Box<Inspection> getInspectionsBox() =>
      Hive.box<Inspection>(inspectionsBox);

  static Future<void> addInspection(Inspection inspection) async {
    final box = getInspectionsBox();
    await box.put(inspection.id, inspection);
  }

  static Future<void> updateInspection(Inspection inspection) async {
    inspection.updatedAt = DateTime.now();
    await addInspection(inspection);
  }

  static Future<void> deleteInspection(String id) async {
    final box = getInspectionsBox();
    await box.delete(id);
  }

  static Inspection? getInspection(String id) {
    final box = getInspectionsBox();
    return box.get(id);
  }

  static List<Inspection> getAllInspections() {
    final box = getInspectionsBox();
    return box.values.toList()
      ..sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
  }

  static List<Inspection> getInspectionsByVehicle(String vehicleId) {
    final box = getInspectionsBox();
    return box.values
        .where((i) => i.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
  }

  static List<Vehicle> getVehiclesNeedingAttention() {
    final vehicles = getAllVehicles();
    return vehicles.where((v) {
      return v.isWofExpired ||
          v.isWofExpiringSoon ||
          v.isRegoExpired ||
          v.isRegoExpiringSoon;
    }).toList();
  }

  // Notification Settings operations
  static Box<NotificationSettings> getNotificationSettingsBox() =>
      Hive.box<NotificationSettings>(notificationSettingsBox);

  static Future<void> saveNotificationSettings(
      NotificationSettings settings) async {
    final box = getNotificationSettingsBox();
    await box.put(settings.vehicleId, settings);
  }

  static NotificationSettings? getNotificationSettings(String vehicleId) {
    final box = getNotificationSettingsBox();
    return box.get(vehicleId);
  }

  static NotificationSettings getOrCreateNotificationSettings(
      String vehicleId) {
    var settings = getNotificationSettings(vehicleId);
    if (settings == null) {
      settings = NotificationSettings(
        id: vehicleId,
        vehicleId: vehicleId,
      );
      saveNotificationSettings(settings);
    }
    return settings;
  }
}
