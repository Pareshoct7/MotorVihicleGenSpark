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
  }

  static Future<void> populateInitialData() async {
    final isPopulated = await PreferencesService.isInitialDataPopulated();
    if (isPopulated) return;

    // Create Stores
    final store1 = Store(
      id: 'store_1',
      name: 'Dominos Koutu 98683',
      address: 'Koutu',
      phone: '98683', 
    );
    final store2 = Store(
      id: 'store_2',
      name: 'Dominos Redwoods 98683',
      address: 'Redwoods',
      phone: '98683',
    );
    
    await addStore(store1);
    await addStore(store2);

    // Create Vehicles
    /*
    KUC487: 2007 Nissan March, Rego 25/05/26, WOF 13/10/26.
    MTC133: 2008 Nissan March, Rego 01/04/26, WOF 13/10/26.
    QNE411: 2006 Suzuki Swift, Rego 09/04/26, WOF 18/03/26.
    CLD968: 2004 Nissan March, Rego 31/03/26, WOF 01/01/26.
    MTC133: 2008 Nissan March, Rego 02/06/26, WOF 27/05/26.
    */
    
    final vehicles = [
      Vehicle(
        id: 'vehicle_1',
        registrationNo: 'KUC487',
        make: 'Nissan',
        model: 'March',
        year: 2007,
        regoExpiryDate: DateTime(2026, 5, 25),
        wofExpiryDate: DateTime(2026, 10, 13),
        storeId: store1.id, // Randomly assigning store 1
      ),
      Vehicle(
        id: 'vehicle_2',
        registrationNo: 'MTC133',
        make: 'Nissan',
        model: 'March',
        year: 2008,
        regoExpiryDate: DateTime(2026, 4, 1),
        wofExpiryDate: DateTime(2026, 10, 13),
        storeId: store1.id,
      ),
      Vehicle(
        id: 'vehicle_3',
        registrationNo: 'QNE411',
        make: 'Suzuki',
        model: 'Swift',
        year: 2006,
        regoExpiryDate: DateTime(2026, 4, 9),
        wofExpiryDate: DateTime(2026, 3, 18),
        storeId: store2.id, // Assigning store 2
      ),
      Vehicle(
        id: 'vehicle_4',
        registrationNo: 'CLD968',
        make: 'Nissan',
        model: 'March',
        year: 2004,
        regoExpiryDate: DateTime(2026, 3, 31),
        wofExpiryDate: DateTime(2026, 1, 1),
        storeId: store2.id,
      ),
      Vehicle(
        id: 'vehicle_5',
        registrationNo: 'MTC133', // Duplicate plate as requested
        make: 'Nissan',
        model: 'March',
        year: 2008,
        regoExpiryDate: DateTime(2026, 6, 2),
        wofExpiryDate: DateTime(2026, 5, 27),
        storeId: store1.id,
      ),
    ];

    for (final vehicle in vehicles) {
      await addVehicle(vehicle);
    }

    if (vehicles.isNotEmpty) {
      await PreferencesService.setDefaultVehicle(vehicles.first.id);
    }

    // Create Drivers
    final drivers = [
      // Koutu Drivers (Store 1)
      Driver(id: 'driver_k1', name: 'Paresh Patil'),
      Driver(id: 'driver_k2', name: 'Janmesh Patel'),
      Driver(id: 'driver_k3', name: 'Shradhadha Joshi'),
      Driver(id: 'driver_k4', name: 'Vijaypala Thisara'),
      Driver(id: 'driver_k5', name: 'Rikin Patel'),
      
      // Redwoods Drivers (Store 2)
      // Note: In current model Driver doesn't explicitly link to Store, 
      // but we populate them so they are available for selection.
      Driver(id: 'driver_r1', name: 'Abhishek Joshi'),
      Driver(id: 'driver_r2', name: 'Jatin Surati'),
      Driver(id: 'driver_r3', name: 'Parthkumar Pandya'),
      Driver(id: 'driver_r4', name: 'Raj Soni'),
      Driver(id: 'driver_r5', name: 'Kashish Joshi'),
    ];

    for (final driver in drivers) {
      await addDriver(driver); // Assuming addDriver exists (checking below)
    }

    await PreferencesService.setInitialDataPopulated(true);
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
