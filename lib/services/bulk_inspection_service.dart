import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/inspection.dart';
import '../models/vehicle.dart';
import '../models/store.dart';
import '../models/driver.dart';

class BulkInspectionService {
  static final Random _random = Random();

  /// Generates a single inspection object with mocked data
  static Inspection generateInspection({
    required Vehicle vehicle,
    required Store store,
    required Driver driver,
    required DateTime date,
    required int odometer,
  }) {
    return Inspection(
      id: const Uuid().v4(),
      vehicleId: vehicle.id,
      storeId: store.id,
      driverId: driver.id,
      inspectionDate: date,
      odometerReading: odometer.toString(),
      vehicleRegistrationNo: vehicle.registrationNo,
      storeName: store.name,
      employeeName: driver.name,
      // All checkboxes set to true (passed inspection)
      tyresTreadDepth: true,
      wheelNuts: true,
      cleanliness: true,
      bodyDamage: true,
      mirrorsWindows: true,
      signage: true,
      engineOilWater: true,
      brakes: true,
      transmission: true,
      tailLights: true,
      headlightsLowBeam: true,
      headlightsHighBeam: true,
      reverseLights: true,
      brakeLights: true,
      windscreenWipers: true,
      horn: true,
      indicators: true,
      seatBelts: true,
      cabCleanliness: true,
      serviceLogBook: true,
      spareKeys: true,
      correctiveActions: 'Routine inspection - No issues found',
      signature: driver.name,
      managerSignature: 'Abhishek Joshi',
      managerSignOffDate: date,
    );
  }

  /// Calculates odometer readings for a series of weeks BEFORE the current date.
  /// Returns a map of Date -> Odometer.
  /// [weeksBack] is the number of past weeks to include.
  /// [baseOdometer] is the CURRENT odometer reading (used as the anchor).
  static Map<DateTime, int> calculateBackdatedOdometers({
    required int weeksBack,
    required int baseOdometer,
    required DateTime anchorDate,
  }) {
    final Map<DateTime, int> readings = {};
    int currentReading = baseOdometer;

    // We start from the most recent Monday before (or on) likely anchorDate
    // But typically we are given a specific set of dates.
    // Let's assume we iterate backwards week by week from now.
    
    DateTime currentProcessingDate = _getMostRecentMonday(anchorDate);
    
    // For the current week (newest), we use valid reading.
    // Then we subtract for previous weeks.
    
    for (int i = 0; i < weeksBack; i++) {
      readings[currentProcessingDate] = currentReading;
      
      // Prep for next iteration (going back in time)
      final subtraction = 100 + _random.nextInt(401); // 100-500 km
      currentReading = currentReading - subtraction;
      if (currentReading < 0) currentReading = 0;
      
      currentProcessingDate = currentProcessingDate.subtract(const Duration(days: 7));
    }

    return readings;
  }

  static DateTime _getMostRecentMonday(DateTime date) {
    if (date.weekday == DateTime.monday) return date;
    int diff = date.weekday - DateTime.monday;
    if (diff < 0) diff += 7;
    return date.subtract(Duration(days: diff));
  }
}
