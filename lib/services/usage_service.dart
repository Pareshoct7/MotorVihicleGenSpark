import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  static const String _usageKeyPrefix = 'feature_usage_';
  
  // Feature identifiers
  static const String featureNewInspection = 'new_inspection';
  static const String featureManageVehicles = 'manage_vehicles';
  static const String featureManageStores = 'manage_stores';
  static const String featureManageDrivers = 'manage_drivers';
  static const String featureOfflineDrive = 'offline_drive';
  static const String featureBulkReports = 'bulk_reports';
  static const String featureReportsAnalytics = 'reports_analytics';
  static const String featureReminders = 'reminders';

  static final List<String> allFeatures = [
    featureNewInspection,
    featureManageVehicles,
    featureManageStores,
    featureManageDrivers,
    featureOfflineDrive,
    featureBulkReports,
    featureReportsAnalytics,
    featureReminders,
  ];

  /// Increment the usage count for a specific feature
  static Future<void> trackUsage(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('$_usageKeyPrefix$featureId') ?? 0;
    await prefs.setInt('$_usageKeyPrefix$featureId', currentCount + 1);
  }

  /// Get the usage count for a specific feature
  static Future<int> getUsageCount(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_usageKeyPrefix$featureId') ?? 0;
  }

  /// Get features sorted by usage count (descending)
  static Future<List<String>> getTopFeatures({int limit = 4}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<MapEntry<String, int>> featureCounts = [];

    for (final feature in allFeatures) {
      final count = prefs.getInt('$_usageKeyPrefix$feature') ?? 0;
      featureCounts.add(MapEntry(feature, count));
    }

    // Sort by count descending
    featureCounts.sort((a, b) => b.value.compareTo(a.value));

    return featureCounts.take(limit).map((e) => e.key).toList();
  }

  /// Get feature titles and icons for UI
  static Map<String, dynamic> getFeatureMeta(String featureId) {
    switch (featureId) {
      case featureNewInspection:
        return {'title': 'Speed Check', 'icon': 0xe09b, 'color': 0xFF4FC3F7}; // Icons.auto_awesome (Sparkly/Nitro)
      case featureManageVehicles:
        return {'title': 'Garage', 'icon': 0xe1d1, 'color': 0xFFFF5252}; // Icons.directions_car
      case featureManageStores:
        return {'title': 'Store Hub', 'icon': 0xe60a, 'color': 0xFFAB47BC}; // Icons.store
      case featureManageDrivers:
        return {'title': 'Driver Hub', 'icon': 0xe001, 'color': 0xFF2196F3}; // Icons.badge
      case featureOfflineDrive:
        return {'title': 'Pizza Drive', 'icon': 0xe39a, 'color': 0xFFFFC107}; // Icons.local_pizza
      case featureBulkReports:
        return {'title': 'Quick Reports', 'icon': 0xf83d, 'color': 0xFF00E676}; // Icons.bolt
      case featureReportsAnalytics:
        return {'title': 'Performance', 'icon': 0xe092, 'color': 0xFF00BCD4}; // Icons.assessment
      case featureReminders:
        return {'title': 'Alert Hub', 'icon': 0xe451, 'color': 0xFFFF9800}; // Icons.notification_important
      default:
        return {'title': 'Unknown', 'icon': 0xe33c, 'color': 0xFF9E9E9E};
    }
  }
}
