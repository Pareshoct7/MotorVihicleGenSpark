import 'dart:math';
import '../services/database_service.dart';

class PredictionService {
  /// Predicts the current odometer reading for a vehicle based on its history.
  /// This uses a simple linear regression (average daily mileage) approach.
  static int? predictOdometer(String vehicleId) {
    final vehicle = DatabaseService.getVehicle(vehicleId);
    if (vehicle == null ||
        vehicle.odometerReading == null ||
        vehicle.odometerUpdatedAt == null) {
      return null;
    }

    final inspections = DatabaseService.getAllInspections()
        .where((i) => i.vehicleId == vehicleId)
        .toList();

    if (inspections.length < 2) {
      // Not enough history for a trend
      return vehicle.odometerReading;
    }

    // Sort by date 
    inspections.sort((a, b) => a.inspectionDate.compareTo(b.inspectionDate));

    // Filter valid readings
    final List<Map<String, dynamic>> validPoints = [];
    
    for (var i = 0; i < inspections.length; i++) {
        final odo = int.tryParse(inspections[i].odometerReading);
        if (odo != null && odo > 0) {
            // Ensure strictly increasing (simple filter)
            if (validPoints.isEmpty || odo >= validPoints.last['odo']) {
                validPoints.add({
                    'date': inspections[i].inspectionDate,
                    'odo': odo
                });
            }
        }
    }

    if (validPoints.length < 2) return vehicle.odometerReading;

    final firstLog = validPoints.first;
    final lastLog = validPoints.last;

    final firstOdo = firstLog['odo'] as int;
    final lastOdo = lastLog['odo'] as int;
    final firstDate = firstLog['date'] as DateTime;
    final lastDate = lastLog['date'] as DateTime;

    final daysDiff = lastDate.difference(firstDate).inDays;

    if (daysDiff == 0) return lastOdo;

    double averageDailyMileage = (lastOdo - firstOdo) / daysDiff;

    // sanity check: cap at 1000km/day
    if (averageDailyMileage > 1000) averageDailyMileage = 1000;
    if (averageDailyMileage < 0) averageDailyMileage = 0;

    final daysSinceLastLog = DateTime.now()
        .difference(lastDate)
        .inDays;

    // Prediction = Last Known + (Average Daily * Days Since Last)
    // Use max(lastOdo, prediction) to ensure we NEVER subtract if daysSinceLastLog is negative for some reason
    // or if averageDailyMileage is 0.
    final prediction =
        lastOdo + (averageDailyMileage * daysSinceLastLog).round();

    return max(lastOdo, prediction);
  }

  /// Calculates the "Freshness" of a vehicle's data.
  /// Returns a value between 0.0 and 1.0.
  static double getDataConfidence(String vehicleId) {
    final vehicle = DatabaseService.getVehicle(vehicleId);
    if (vehicle == null || vehicle.odometerUpdatedAt == null) return 0.0;

    final daysOld = DateTime.now()
        .difference(vehicle.odometerUpdatedAt!)
        .inDays;
    if (daysOld > 30) return 0.2; // Very stale
    if (daysOld > 7) return 0.5; // Getting old
    return 1.0; // Fresh
  }
}
