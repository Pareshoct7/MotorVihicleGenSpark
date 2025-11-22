import '../models/inspection.dart';
import '../models/vehicle.dart';
import 'database_service.dart';

/// Predictive Maintenance and Analytics Service
/// 
/// Provides smart predictions based on inspection history
class PredictionService {
  /// Predict next service date based on inspection history
  static Future<Map<String, dynamic>> predictNextService(String vehicleId) async {
    final inspections = DatabaseService.getAllInspections()
        .where((i) => i.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
    
    if (inspections.length < 2) {
      return {
        'canPredict': false,
        'message': 'Need at least 2 inspection records for prediction',
      };
    }
    
    // Calculate average interval between inspections
    int totalDays = 0;
    for (int i = 0; i < inspections.length - 1; i++) {
      final days = inspections[i].inspectionDate
          .difference(inspections[i + 1].inspectionDate)
          .inDays;
      totalDays += days;
    }
    
    final avgInterval = totalDays / (inspections.length - 1);
    final lastInspection = inspections.first;
    final predictedDate = lastInspection.inspectionDate.add(
      Duration(days: avgInterval.round()),
    );
    
    // Calculate confidence based on data consistency
    String confidence;
    if (inspections.length >= 5) {
      confidence = 'high';
    } else if (inspections.length >= 3) {
      confidence = 'medium';
    } else {
      confidence = 'low';
    }
    
    return {
      'canPredict': true,
      'predictedDate': predictedDate,
      'avgIntervalDays': avgInterval.round(),
      'lastInspectionDate': lastInspection.inspectionDate,
      'confidence': confidence,
      'dataPoints': inspections.length,
    };
  }
  
  /// Identify recurring issues across inspections
  static Future<List<Map<String, dynamic>>> identifyRecurringIssues(String vehicleId) async {
    final inspections = DatabaseService.getAllInspections()
        .where((i) => i.vehicleId == vehicleId)
        .toList();
    
    if (inspections.length < 3) return [];
    
    final issues = <Map<String, dynamic>>[];
    
    // Track failed items across inspections
    final failedItems = <String, int>{};
    
    for (final inspection in inspections) {
      if (inspection.tyresTreadDepth == false) {
        failedItems['Tyres (tread depth)'] = (failedItems['Tyres (tread depth)'] ?? 0) + 1;
      }
      if (inspection.wheelNuts == false) {
        failedItems['Wheel nuts'] = (failedItems['Wheel nuts'] ?? 0) + 1;
      }
      if (inspection.brakes == false) {
        failedItems['Brakes'] = (failedItems['Brakes'] ?? 0) + 1;
      }
      if (inspection.engineOilWater == false) {
        failedItems['Engine oil & water'] = (failedItems['Engine oil & water'] ?? 0) + 1;
      }
      if (inspection.transmission == false) {
        failedItems['Transmission'] = (failedItems['Transmission'] ?? 0) + 1;
      }
      if (inspection.tailLights == false) {
        failedItems['Tail lights'] = (failedItems['Tail lights'] ?? 0) + 1;
      }
      if (inspection.headlightsLowBeam == false) {
        failedItems['Headlights (low beam)'] = (failedItems['Headlights (low beam)'] ?? 0) + 1;
      }
      if (inspection.headlightsHighBeam == false) {
        failedItems['Headlights (high beam)'] = (failedItems['Headlights (high beam)'] ?? 0) + 1;
      }
      if (inspection.brakeLights == false) {
        failedItems['Brake lights'] = (failedItems['Brake lights'] ?? 0) + 1;
      }
      if (inspection.windscreenWipers == false) {
        failedItems['Windscreen & wipers'] = (failedItems['Windscreen & wipers'] ?? 0) + 1;
      }
    }
    
    // Items that failed in 40% or more inspections are considered recurring
    final threshold = inspections.length * 0.4;
    for (final entry in failedItems.entries) {
      if (entry.value >= threshold) {
        final failureRate = (entry.value / inspections.length * 100).round();
        issues.add({
          'item': entry.key,
          'failureCount': entry.value,
          'totalInspections': inspections.length,
          'failureRate': failureRate,
          'severity': failureRate >= 70 ? 'high' : failureRate >= 50 ? 'medium' : 'low',
        });
      }
    }
    
    // Sort by failure rate (highest first)
    issues.sort((a, b) => (b['failureRate'] as int).compareTo(a['failureRate'] as int));
    
    return issues;
  }
  
  /// Get inspection trend (improving/declining/stable)
  static Future<Map<String, dynamic>> getInspectionTrend(String vehicleId) async {
    final inspections = DatabaseService.getAllInspections()
        .where((i) => i.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => a.inspectionDate.compareTo(b.inspectionDate)); // Oldest first
    
    if (inspections.length < 3) {
      return {
        'trend': 'insufficient_data',
        'message': 'Need at least 3 inspections to determine trend',
      };
    }
    
    // Compare recent inspections vs older ones
    final recentCount = (inspections.length * 0.3).ceil(); // Last 30%
    final olderCount = (inspections.length * 0.3).ceil(); // First 30%
    
    final recentInspections = inspections.reversed.take(recentCount).toList();
    final olderInspections = inspections.take(olderCount).toList();
    
    final recentAvgCompletion = recentInspections
        .map((i) => i.completionPercentage)
        .reduce((a, b) => a + b) / recentCount;
    
    final olderAvgCompletion = olderInspections
        .map((i) => i.completionPercentage)
        .reduce((a, b) => a + b) / olderCount;
    
    final difference = recentAvgCompletion - olderAvgCompletion;
    
    String trend;
    String message;
    
    if (difference > 5) {
      trend = 'improving';
      message = 'Vehicle condition is improving over time';
    } else if (difference < -5) {
      trend = 'declining';
      message = 'Vehicle condition is declining, may need attention';
    } else {
      trend = 'stable';
      message = 'Vehicle condition is stable';
    }
    
    return {
      'trend': trend,
      'message': message,
      'recentAverage': recentAvgCompletion.toStringAsFixed(1),
      'olderAverage': olderAvgCompletion.toStringAsFixed(1),
      'difference': difference.toStringAsFixed(1),
      'dataPoints': inspections.length,
    };
  }
  
  /// Calculate maintenance cost prediction (placeholder for future enhancement)
  static Future<Map<String, dynamic>> predictMaintenanceCost(String vehicleId) async {
    final recurringIssues = await identifyRecurringIssues(vehicleId);
    
    // Simplified cost estimation based on recurring issues
    double estimatedCost = 0.0;
    
    for (final issue in recurringIssues) {
      final severity = issue['severity'] as String;
      switch (severity) {
        case 'high':
          estimatedCost += 500; // High severity items
          break;
        case 'medium':
          estimatedCost += 250; // Medium severity items
          break;
        case 'low':
          estimatedCost += 100; // Low severity items
          break;
      }
    }
    
    return {
      'estimatedCost': estimatedCost,
      'currency': 'USD',
      'issuesFound': recurringIssues.length,
      'note': 'This is an estimated cost based on recurring issues',
    };
  }
}
