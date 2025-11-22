import 'package:hive/hive.dart';

/// AI Learning Service for smart auto-complete and behavior learning
/// 
/// This service records user inputs and provides intelligent suggestions
/// based on frequency and patterns.
class AILearningService {
  static const String _boxName = 'ai_learning';
  static late Box<Map<dynamic, dynamic>> _learningBox;
  
  static Future<void> init() async {
    _learningBox = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }
  
  /// Record user input for a specific field
  static Future<void> recordInput(String fieldName, String value) async {
    if (value.trim().isEmpty) return;
    
    final key = 'field_$fieldName';
    final data = _learningBox.get(key, defaultValue: <String, int>{}) as Map;
    final mutableData = Map<String, int>.from(data.map((k, v) => MapEntry(k.toString(), v as int)));
    
    // Count frequency of this input
    final count = mutableData[value] ?? 0;
    mutableData[value] = count + 1;
    
    await _learningBox.put(key, mutableData);
  }
  
  /// Get suggestions for a field based on input prefix
  static List<String> getSuggestions(String fieldName, String prefix) {
    final key = 'field_$fieldName';
    final data = _learningBox.get(key, defaultValue: <String, int>{});
    
    if (data == null || data.isEmpty) return [];
    
    // Filter by prefix and sort by frequency
    final suggestions = data.entries
        .where((entry) {
          final text = entry.key.toString().toLowerCase();
          final searchText = prefix.toLowerCase();
          return text.contains(searchText);
        })
        .toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return suggestions
        .map((entry) => entry.key.toString())
        .take(5)
        .toList();
  }
  
  /// Get most frequently used values for a field
  static List<String> getTopValues(String fieldName, {int limit = 3}) {
    final key = 'field_$fieldName';
    final data = _learningBox.get(key, defaultValue: <String, int>{});
    
    if (data == null || data.isEmpty) return [];
    
    final sorted = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return sorted
        .map((entry) => entry.key.toString())
        .take(limit)
        .toList();
  }
  
  /// Get usage count for a specific value
  static int getUsageCount(String fieldName, String value) {
    final key = 'field_$fieldName';
    final data = _learningBox.get(key, defaultValue: <String, int>{});
    
    if (data == null) return 0;
    return (data[value] as int?) ?? 0;
  }
  
  /// Clear learning data for a specific field
  static Future<void> clearFieldData(String fieldName) async {
    final key = 'field_$fieldName';
    await _learningBox.delete(key);
  }
  
  /// Clear all learning data
  static Future<void> clearAllData() async {
    await _learningBox.clear();
  }
  
  /// Get statistics for debugging/analytics
  static Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    
    for (final key in _learningBox.keys) {
      final data = _learningBox.get(key);
      if (data != null) {
        final totalEntries = data.length;
        final totalUsage = data.values.fold<int>(0, (sum, count) => sum + (count as int));
        
        stats[key.toString()] = {
          'entries': totalEntries,
          'totalUsage': totalUsage,
        };
      }
    }
    
    return stats;
  }
}
