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
      odometerReading: odometer.toString().padLeft(6, '0'),
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
    required DateTime startDate,
    int? vehicleYear,
    int? seed,
  }) {
    final Map<DateTime, int> readings = {};
    
    // Estimate a floor if base is 0
    final int currentYear = DateTime.now().year;
    final int age = vehicleYear != null ? (currentYear - vehicleYear) : 5;
    final int estimatedBase = (age * 10000).clamp(5000, 250000);
    
    int internalBaseOdo = baseOdometer;
    if (internalBaseOdo < 100) {
        internalBaseOdo = estimatedBase;
    }

    // 1. Generate the list of 52 Mondays (newest to oldest)
    List<DateTime> mondays = [];
    DateTime currentMonday = _getMostRecentMonday(startDate);
    for (int i = 0; i < weeksBack; i++) {
        mondays.add(currentMonday);
        currentMonday = currentMonday.subtract(const Duration(days: 7));
    }

    // 2. Find the index of the Monday closest to the anchorDate
    int anchorIndex = 0;
    int minDiff = 1000000;
    for (int i = 0; i < mondays.length; i++) {
        int diff = mondays[i].difference(anchorDate).inDays.abs();
        if (diff < minDiff) {
            minDiff = diff;
            anchorIndex = i;
        }
    }

    // 3. Set the anchor value
    readings[mondays[anchorIndex]] = internalBaseOdo;

    // Use a seeded random if provided for consistent trends across syncs
    final random = seed != null ? Random(seed) : Random();

    // 4. Step FORWARD in time (down the indices from anchorIndex to 0)
    int upReading = internalBaseOdo;
    for (int i = anchorIndex - 1; i >= 0; i--) {
        upReading += 50 + random.nextInt(101); // 50 to 150
        readings[mondays[i]] = upReading;
    }

    // 5. Step BACKWARD in time (up the indices from anchorIndex to weeksBack - 1)
    int downReading = internalBaseOdo;
    for (int i = anchorIndex + 1; i < mondays.length; i++) {
        downReading -= 50 + random.nextInt(101); // 50 to 150
        if (downReading < 500) downReading = 500;
        readings[mondays[i]] = downReading;
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
