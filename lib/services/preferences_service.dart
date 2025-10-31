import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _defaultStoreKey = 'default_store_id';
  static const String _defaultDriverKey = 'default_driver_id';
  static const String _defaultVehicleKey = 'default_vehicle_id';

  static Future<void> setDefaultStore(String? storeId) async {
    final prefs = await SharedPreferences.getInstance();
    if (storeId != null) {
      await prefs.setString(_defaultStoreKey, storeId);
    } else {
      await prefs.remove(_defaultStoreKey);
    }
  }

  static Future<String?> getDefaultStore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultStoreKey);
  }

  static Future<void> setDefaultDriver(String? driverId) async {
    final prefs = await SharedPreferences.getInstance();
    if (driverId != null) {
      await prefs.setString(_defaultDriverKey, driverId);
    } else {
      await prefs.remove(_defaultDriverKey);
    }
  }

  static Future<String?> getDefaultDriver() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultDriverKey);
  }

  static Future<void> setDefaultVehicle(String? vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    if (vehicleId != null) {
      await prefs.setString(_defaultVehicleKey, vehicleId);
    } else {
      await prefs.remove(_defaultVehicleKey);
    }
  }

  static Future<String?> getDefaultVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultVehicleKey);
  }
}
