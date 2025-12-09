import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vehicle.dart';
import '../models/store.dart';
import '../models/driver.dart';
import '../models/inspection.dart';
import 'database_service.dart';

class DataBackupService {
  static const int _currentVersion = 1;

  /// Export the entire database to a JSON file and share it
  static Future<void> exportDatabase() async {
    try {
      final vehicles = DatabaseService.getAllVehicles();
      final stores = DatabaseService.getAllStores();
      final drivers = DatabaseService.getAllDrivers();
      final inspections = DatabaseService.getAllInspections();

      final data = {
        'version': _currentVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
        'stores': stores.map((s) => s.toJson()).toList(),
        'drivers': drivers.map((d) => d.toJson()).toList(),
        'inspections': inspections.map((i) => i.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'vehicle_inspection_backup_$timestamp.json';

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Vehicle Inspection App Backup',
      );
    } catch (e) {
      throw Exception('Failed to export database: $e');
    }
  }

  /// Import database from a JSON file
  /// Returns true if successful, false if cancelled
  static Future<bool> importDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version if needed
      // final version = data['version'] as int;

      // Import Vehicles
      if (data.containsKey('vehicles')) {
        final vehiclesList = data['vehicles'] as List;
        for (var vJson in vehiclesList) {
          final vehicle = Vehicle.fromJson(vJson);
          await DatabaseService.addVehicle(vehicle);
        }
      }

      // Import Stores
      if (data.containsKey('stores')) {
        final storesList = data['stores'] as List;
        for (var sJson in storesList) {
          final store = Store.fromJson(sJson);
          await DatabaseService.addStore(store);
        }
      }

      // Import Drivers
      if (data.containsKey('drivers')) {
        final driversList = data['drivers'] as List;
        for (var dJson in driversList) {
          final driver = Driver.fromJson(dJson);
          await DatabaseService.addDriver(driver);
        }
      }

      // Import Inspections
      if (data.containsKey('inspections')) {
        final inspectionsList = data['inspections'] as List;
        for (var iJson in inspectionsList) {
          final inspection = Inspection.fromJson(iJson);
          await DatabaseService.addInspection(inspection);
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to import database: $e');
    }
  }
}
