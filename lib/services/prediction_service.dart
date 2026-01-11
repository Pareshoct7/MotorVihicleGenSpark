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
      // Not enough history for a trend, just return current if very recent,
      // or current + a small default increment.
      return vehicle.odometerReading;
    }

    // Sort by date to get the earliest and latest logs
    inspections.sort((a, b) => a.inspectionDate.compareTo(b.inspectionDate));

    final firstLog = inspections.first;
    final lastLog = inspections.last;

    final firstOdo =
        int.tryParse(firstLog.odometerReading) ?? vehicle.odometerReading!;
    final lastOdo =
        int.tryParse(lastLog.odometerReading) ?? vehicle.odometerReading!;

    final daysDiff = lastLog.inspectionDate
        .difference(firstLog.inspectionDate)
        .inDays;

    if (daysDiff == 0) return lastOdo;

    final averageDailyMileage = (lastOdo - firstOdo) / daysDiff;

    final daysSinceLastLog = DateTime.now()
        .difference(lastLog.inspectionDate)
        .inDays;

    // Prediction = Last Known + (Average Daily * Days Since Last)
    final prediction =
        lastOdo + (averageDailyMileage * daysSinceLastLog).round();

    return prediction;
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
