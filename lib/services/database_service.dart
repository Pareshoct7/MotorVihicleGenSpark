import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/store.dart';
import '../models/driver.dart';
import '../models/inspection.dart';
import '../models/notification_settings.dart';
import 'ai_learning_service.dart';
import 'preferences_service.dart';

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

    await populateInitialData();
    await cleanupDemoData();
  }

  static Future<void> cleanupDemoData() async {
    // PURGE ONLY THE FALSE DEMO RECORDS (Named "Dominos Koutu 98683")
    // Keep "Dominos Koutu 98667" (store_1)
    
    final inspectionsBox = Hive.box<Inspection>('inspections');
    final inspectionsToRemove = inspectionsBox.values
        .where((i) => i.storeId == 'store_1' && i.storeName.contains('98683'))
        .toList();
    
    for (var i in inspectionsToRemove) {
        print('Purging demo inspection: ${i.id} at 98683');
        await i.delete();
    }

    // Force restore store_1 if it was accidentally deleted
    final storesBox = Hive.box<Store>('stores');
    if (!storesBox.containsKey('store_1')) {
        print('Restoring store_1 (Dominos Koutu 98667)');
        await storesBox.put('store_1', Store(
            id: 'store_1',
            name: 'Dominos Koutu 98667',
            address: 'Koutu',
            phone: '02108760034',
        ));
    }

    // Force restore Koutu drivers if they were accidentally deleted
    final driversBox = Hive.box<Driver>('drivers');
    final kDrivers = [
      {'id': 'driver_k1', 'name': 'Paresh Patil'},
      {'id': 'driver_k2', 'name': 'Janmesh Patel'},
      {'id': 'driver_k3', 'name': 'Shradhadha Joshi'},
      {'id': 'driver_k4', 'name': 'Vijaypala Thisara'},
      {'id': 'driver_k5', 'name': 'Rikin Patel'},
    ];

    for (var d in kDrivers) {
      if (!driversBox.containsKey(d['id'])) {
         print('Restoring Koutu driver: ${d['name']}');
         await driversBox.put(d['id'], Driver(
           id: d['id']!,
           name: d['name']!,
         ));
      }
    }

    // Force restore Koutu vehicles if they were accidentally deleted
    final vBox = Hive.box<Vehicle>(vehiclesBox);
    final existingStore1Vehicles = vBox.values.where((v) => v.storeId == 'store_1').toList();
    
    if (existingStore1Vehicles.isEmpty) {
        print('Detected missing vehicles for store_1. Re-seeding from JSON...');
        try {
            final jsonString = await rootBundle.loadString('assets/initial_data.json');
            final Map<String, dynamic> data = json.decode(jsonString);
            if (data['vehicles'] != null) {
                final vehiclesList = (data['vehicles'] as List)
                    .map((i) => Vehicle.fromJson(i))
                    .where((v) => v.storeId == 'store_1')
                    .toList();
                for (var v in vehiclesList) {
                    await vBox.put(v.id, v);
                    print('Restored vehicle: ${v.registrationNo}');
                }
            }
        } catch (e) {
            print('Error restoring Koutu vehicles: $e');
        }
    }
  }

  static Future<void> populateInitialData() async {
    final isPopulated = await PreferencesService.isInitialDataPopulated();
    if (isPopulated) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/initial_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      // Vehicles
      if (data['vehicles'] != null) {
        final vehiclesList = (data['vehicles'] as List)
            .map((i) => Vehicle.fromJson(i))
            .toList();
        for (var v in vehiclesList) {
          await addVehicle(v);
        }
        if (vehiclesList.isNotEmpty) {
          await PreferencesService.setDefaultVehicle(vehiclesList.first.id);
        }
      }

      // Stores
      if (data['stores'] != null) {
        final storesList =
            (data['stores'] as List).map((i) => Store.fromJson(i)).toList();
        for (var s in storesList) {
          await addStore(s);
        }
      }

      // Drivers
      if (data['drivers'] != null) {
        final driversList =
            (data['drivers'] as List).map((i) => Driver.fromJson(i)).toList();
        for (var d in driversList) {
          await addDriver(d);
        }
      }

      // Inspections
      if (data['inspections'] != null) {
        final inspectionsList = (data['inspections'] as List)
            .map((i) => Inspection.fromJson(i))
            .toList();
        for (var i in inspectionsList) {
          await addInspection(i);
        }
      }

      await PreferencesService.setInitialDataPopulated(true);
      print('Initial data populated successfully from JSON.');
    } catch (e) {
      print("Error seeding database: $e");
    }
  }

  // Inspection operations
  static Box<Inspection> getInspectionsBox() =>
      Hive.box<Inspection>(inspectionsBox);
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

  /// Check if an inspection already exists for this vehicle in the same calendar week
  static bool hasInspectionInSameWeek(String vehicleId, DateTime date) {
    final inspections = getInspectionsByVehicle(vehicleId);
    
    // Calculate week number for the target date
    final targetWeek = _getWeekNumber(date);
    final targetYear = date.year; // Note: ISO weeks can cross years, but simple year match is usually sufficient for this app's scale

    for (final inspection in inspections) {
      final inspectionWeek = _getWeekNumber(inspection.inspectionDate);
      final inspectionYear = inspection.inspectionDate.year;

      if (inspectionYear == targetYear && inspectionWeek == targetWeek) {
        return true;
      }
    }
    return false;
  }

  /// Helper to calculate week number (ISO 8601-ish)
  static int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
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
