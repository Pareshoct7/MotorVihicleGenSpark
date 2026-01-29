import 'dart:io';
import 'dart:math';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/inspection.dart';
import '../models/store.dart';
import '../models/driver.dart';
import 'database_service.dart';
import 'pdf_service.dart';
import 'bulk_inspection_service.dart';
import 'prediction_service.dart';

class OfflineDriveService {
  static Directory? _rootDir;

  static Future<void> init() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _rootDir = Directory('${appDocDir.path}/OfflineDrive');
      if (!_rootDir!.existsSync()) {
        _rootDir!.createSync(recursive: true);
      }
      await cleanupDemoFolders();
      debugPrint('Offline Drive Initialized at: ${_rootDir!.path}');
    } catch (e) {
      debugPrint('Error initializing Offline Drive: $e');
    }
  }

  static Future<void> cleanupDemoFolders() async {
    if (_rootDir == null) return;
    try {
        if (await _rootDir!.exists()) {
            final entities = await _rootDir!.list().toList();
            for (final entity in entities) {
                // ONLY delete if it contains BOTH "Koutu" and "98683" (incorrect store name)
                if (entity is Directory && entity.path.contains('Koutu') && entity.path.contains('98683')) {
                    debugPrint('Cleanup: Deleting INCORRECT demo folder ${entity.path}');
                    await entity.delete(recursive: true);
                }
            }
        }
    } catch (e) {
        debugPrint('Cleanup error: $e');
    }
  }

  /// Creates base Store directories.
  /// Note: Year/Month/Vehicle folders are created on demand.
  static Future<void> syncStructure() async {
    if (_rootDir == null) await init();
    if (_rootDir == null) return;

    final stores = DatabaseService.getAllStores();
    for (final store in stores) {
      final storeDir = Directory('${_rootDir!.path}/${_sanitize(store.name)}');
      if (!await storeDir.exists()) {
        await storeDir.create(recursive: true);
      }
    }
    debugPrint('Offline Drive Base Synced');
  }

  /// Calculates path: .../StoreName/Year/MonthName/VehicleReg/File.pdf
  static Future<String?> saveInspectionPdf(
    Inspection inspection,
    Uint8List pdfBytes,
  ) async {
    if (_rootDir == null) await init();
    if (_rootDir == null) return null;

    try {
      final storeName = _sanitize(inspection.storeName);
      final year = DateFormat('yyyy').format(inspection.inspectionDate);
      final month = DateFormat(
        'MMMM',
      ).format(inspection.inspectionDate); // Full month name
      final vehicleReg = _sanitize(inspection.vehicleRegistrationNo);

      final dateStr = DateFormat(
        'yyyyMMdd_HHmm',
      ).format(inspection.inspectionDate);
      final fileName = 'Inspection_$dateStr.pdf';

      final dirPath = '${_rootDir!.path}/$storeName/$year/$month/$vehicleReg';
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      debugPrint('Saved PDF to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error saving PDF to drive: $e');
      return null;
    }
  }

  /// Scans history and generates missing reports + PDFs.
  /// [weeksBack] defaults to 52 (1 year).
  static Future<void> generateAllBackfill({
    int weeksBack = 52,
    required Function(int completed, int total, String status) onProgress,
  }) async {
    if (_rootDir == null) await init();

    final vehicles = DatabaseService.getAllVehicles();
    final stores = DatabaseService.getAllStores();
    final drivers = DatabaseService.getAllDrivers();
    final random = Random();

    // Fallbacks if data missing
    final defaultStore = stores.isNotEmpty ? stores.first : null;
    final defaultDriver = drivers.isNotEmpty ? drivers.first : null;

    // Total steps estimation: Vehicles * Weeks
    int totalSteps = vehicles.length * weeksBack;
    int currentStep = 0;

    for (final vehicle in vehicles) {
      final store = stores.firstWhere(
        (s) => s.id == vehicle.storeId,
        orElse: () =>
            defaultStore ??
            Store(id: 'unknown', name: 'Unknown Store', address: ''),
      );

      // Try to find a driver. Vehicles don't have driverId, so use default.
      final driver = drivers.isNotEmpty
          ? drivers.first
          : Driver(
              id: 'unknown',
              name: 'Unknown Driver',
              licenseNumber: '',
              phone: '',
            );

      // Get Odometers Timeline
      // Use vehicle.odometerReading and odometerUpdatedAt as the absolute anchor
      final int baseOdometer = vehicle.odometerReading ?? 0;
      final DateTime anchorDate = vehicle.odometerUpdatedAt ?? vehicle.createdAt;
      
      final odometerMap = BulkInspectionService.calculateBackdatedOdometers(
        weeksBack: weeksBack,
        baseOdometer: baseOdometer,
        anchorDate: anchorDate,
        startDate: DateTime.now(),
        vehicleYear: vehicle.year,
        seed: vehicle.id.hashCode,
      );

      for (final date in odometerMap.keys) {
        currentStep++;
        final odometer = odometerMap[date]!;

        // 1. Check Hive for existing inspection for this Vehicle + Date (approx week)
        bool existsInHive = DatabaseService.hasInspectionInSameWeek(
          vehicle.id,
          date,
        );

        Inspection? inspection;

        if (!existsInHive) {
          // Generate NEW Inspection
          onProgress(
            currentStep,
            totalSteps,
            'Generating missing report for ${vehicle.registrationNo} - ${DateFormat('dd/MM').format(date)}',
          );

          // Get drivers specific to this store
          final storeDrivers = _getDriversForStore(store.id, drivers);
          
          // Deterministic selection: One vehicle always gets the same driver
          final driverIndex = (vehicle.id.hashCode).abs() % storeDrivers.length;
          final assignedDriver = storeDrivers.isNotEmpty 
              ? storeDrivers[driverIndex] 
              : (drivers.isNotEmpty ? drivers[random.nextInt(drivers.length)] : driver);

          // Ensure Store Name is consistent (fix for "Dominos Koutu 98683" issue)
          // If the store object has the correct name, use it.
          // The generator uses store.name, so this should be correct if 'store' is correct.

          inspection = BulkInspectionService.generateInspection(
            vehicle: vehicle,
            store: store,
            driver: assignedDriver,
            date: date,
            odometer: odometer,
          );

          await DatabaseService.addInspection(inspection);
        } else {
          // Fetch existing (we need it to save PDF, and ensure signature is present)
          try {
            final all = DatabaseService.getAllInspections();
            inspection = all.firstWhere(
              (i) =>
                  i.vehicleId == vehicle.id &&
                  _isSameWeek(i.inspectionDate, date),
            );

            // FORCE UPDATE: Fix Zero Odometer issues for RHC34 etc.
            // ALSO FORCE UPDATE: If current odometer differs from smart trend by more than 5km
            final currentOdoStr = inspection.odometerReading.replaceAll(RegExp(r'[^0-9]'), '');
            final currentOdoVal = int.tryParse(currentOdoStr) ?? 0;
            
            bool needsSave = false;
            
            if (inspection.managerSignature != 'Abhishek Joshi') {
              inspection.managerSignature = 'Abhishek Joshi';
              inspection.managerSignOffDate = inspection.inspectionDate;
              needsSave = true;
            }

            final diff = (currentOdoVal - odometer).abs();
            if (diff > 5 || currentOdoVal == 0 || inspection.odometerReading.length < 6) {
                 inspection.odometerReading = odometer.toString().padLeft(6, '0');
                 needsSave = true;
            }

            if (needsSave) {
                await inspection.save();
                // If we updated the record, we should probably delete the old PDF so it regenerates
                // But the PDF generation logic below checks `if (!await file.exists())`.
                // So we need to force delete the old PDF file if we updated the record.
                
                final storeName = _sanitize(inspection.storeName);
                final year = DateFormat('yyyy').format(inspection.inspectionDate);
                final month = DateFormat('MMMM').format(inspection.inspectionDate);
                final vehicleReg = _sanitize(inspection.vehicleRegistrationNo);
                final dateStr = DateFormat('yyyyMMdd_HHmm').format(inspection.inspectionDate);
                final fileName = 'Inspection_$dateStr.pdf';
                final filePath = '${_rootDir!.path}/$storeName/$year/$month/$vehicleReg/$fileName';
                
                final oldFile = File(filePath);
                if (await oldFile.exists()) {
                    await oldFile.delete();
                }
            }

            // FORCE RE-RANDOMIZE DRIVER: If driver is "Paresh Patil" or belongs to store_1
            // we should re-assign a proper store_2 driver.
            // ALSO FORCE FIX: If odometer is still 000000 after previous checks
            final isZero = inspection.odometerReading.replaceAll('0', '').isEmpty;
            
            if (inspection.employeeName == 'Paresh Patil' || (inspection.driverId?.startsWith('driver_k') ?? false) || isZero) {
                 final storeDrivers = _getDriversForStore(store.id, drivers);
                 if (storeDrivers.isNotEmpty) {
                     final driverIndex = (vehicle.id.hashCode).abs() % storeDrivers.length;
                     final newDriver = storeDrivers[driverIndex];
                     inspection.driverId = newDriver.id;
                     inspection.employeeName = newDriver.name;
                     inspection.signature = newDriver.name;
                     await inspection.save();
                     
                     // Delete PDF to force regeneration with new driver
                     final storeName = _sanitize(inspection.storeName);
                     final year = DateFormat('yyyy').format(inspection.inspectionDate);
                     final month = DateFormat('MMMM').format(inspection.inspectionDate);
                     final vehicleReg = _sanitize(inspection.vehicleRegistrationNo);
                     final dateStr = DateFormat('yyyyMMdd_HHmm').format(inspection.inspectionDate);
                     final fileName = 'Inspection_$dateStr.pdf';
                     final filePath = '${_rootDir!.path}/$storeName/$year/$month/$vehicleReg/$fileName';
                     final oldFile = File(filePath);
                     if (await oldFile.exists()) {
                        await oldFile.delete();
                     }
                 }
            }
          } catch (e) {
            // Should not happen if hasInspectionInSameWeek returned true
          }
        }

        // 2. Check/Save PDF
        if (inspection != null) {
          onProgress(
            currentStep,
            totalSteps,
            'Verifying PDF for ${vehicle.registrationNo}...',
          );

          final storeName = _sanitize(inspection.storeName);
          final year = DateFormat('yyyy').format(inspection.inspectionDate);
          final month = DateFormat('MMMM').format(inspection.inspectionDate);
          final vehicleReg = _sanitize(inspection.vehicleRegistrationNo);
          final dateStr = DateFormat(
            'yyyyMMdd_HHmm',
          ).format(inspection.inspectionDate);
          final fileName = 'Inspection_$dateStr.pdf';

          final filePath =
              '${_rootDir!.path}/$storeName/$year/$month/$vehicleReg/$fileName';
          final file = File(filePath);

          if (!await file.exists()) {
            try {
              final pdfBytes = await PdfService.generateTemplateMatchingPdf(
                inspection,
              );
              await saveInspectionPdf(inspection, pdfBytes);
            } catch (e) {
              debugPrint('PDF Gen failed: $e');
            }
          }
        }

        // Yield
        if (currentStep % 5 == 0) await Future.delayed(Duration.zero);
      }
    }
  }

  static bool _isSameWeek(DateTime d1, DateTime d2) {
    // Simple util: check if same week year
    // Or just use diff in days < 7 and same weekday
    // Our target dates are Mondays.
    // Let's assume strict match for generated ones, but loose for existing?
    // Let's use logic from DatabaseService or just simple diff
    final diff = d1.difference(d2).inDays.abs();
    return diff < 4; // Within 3-4 days
  }

  static String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  // -- Directory Browsing Utilities --

  static Future<List<FileSystemEntity>> getContents(Directory dir) async {
    if (!await dir.exists()) return [];
    final List<FileSystemEntity> entities = await dir.list().toList();
    // Sort: Directories first, then Files. Alphabetical.
    entities.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });
    return entities;
  }

  static Future<Directory> getRootDirectory() async {
    if (_rootDir == null) await init();
    return _rootDir!;
  }

  /// Recursively collects all PDF files from a directory
  static Future<List<File>> collectPdfsRecursively(Directory dir) async {
    final List<File> pdfFiles = [];

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          pdfFiles.add(entity);
        }
      }
      // Sort by path for consistent ordering
      pdfFiles.sort((a, b) => a.path.compareTo(b.path));
    } catch (e) {
      debugPrint('Error collecting PDFs: $e');
    }

    return pdfFiles;
  }

  /// Generates a clubbed PDF from all inspections in a folder
  static Future<Uint8List?> generateClubbedPdfFromFolder({
    required Directory folder,
    required Function(int current, int total) onProgress,
  }) async {
    try {
      // Collect all PDFs
      onProgress(0, 0);
      final pdfFiles = await collectPdfsRecursively(folder);

      if (pdfFiles.isEmpty) {
        throw Exception('No PDF files found in this folder');
      }

      debugPrint('Found ${pdfFiles.length} PDFs to combine');

      // Get all inspections from Hive
      final allInspections = DatabaseService.getAllInspections();

      // Map PDF files to their corresponding inspections
      final List<Inspection> inspectionsToMerge = [];

      for (final pdfFile in pdfFiles) {
        final matchingInspection = _mapPdfToInspection(pdfFile, allInspections);
        if (matchingInspection != null) {
          inspectionsToMerge.add(matchingInspection);
        }
      }

      if (inspectionsToMerge.isEmpty) {
        throw Exception('Could not map PDF files to inspections');
      }

      debugPrint('Mapped ${inspectionsToMerge.length} inspections');
      onProgress(pdfFiles.length, pdfFiles.length);

      // Generate clubbed PDF using existing service
      final clubbedPdfBytes = await PdfService.generateClubbedInspectionPdf(
        inspectionsToMerge,
      );

      return clubbedPdfBytes;
    } catch (e) {
      debugPrint('Error generating clubbed PDF: $e');
      rethrow;
    }
  }

  /// Delete a file or folder (recursively)
  static Future<void> deleteFileOrFolder(FileSystemEntity entity) async {
    try {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else if (entity is File) {
        await entity.delete();
      }
      debugPrint('Deleted: ${entity.path}');
    } catch (e) {
      debugPrint('Error deleting ${entity.path}: $e');
      rethrow;
    }
  }

  /// Collect PDFs from specific file/folder paths
  static Future<List<File>> collectPdfsFromPaths(List<String> paths) async {
    final Set<File> uniquePdfs = {};

    for (final path in paths) {
      final entity = FileSystemEntity.typeSync(path);

      if (entity == FileSystemEntityType.file &&
          path.toLowerCase().endsWith('.pdf')) {
        uniquePdfs.add(File(path));
      } else if (entity == FileSystemEntityType.directory) {
        final folderPdfs = await collectPdfsRecursively(Directory(path));
        uniquePdfs.addAll(folderPdfs);
      }
    }

    final pdfList = uniquePdfs.toList();
    pdfList.sort((a, b) => a.path.compareTo(b.path));
    return pdfList;
  }

  /// Generate clubbed PDF from specific PDF files
  static Future<Uint8List?> generateClubbedPdfFromFiles({
    required List<File> pdfFiles,
    required Function(int current, int total) onProgress,
  }) async {
    try {
      if (pdfFiles.isEmpty) {
        throw Exception('No PDF files selected');
      }

      onProgress(0, pdfFiles.length);

      final allInspections = DatabaseService.getAllInspections();
      final List<Inspection> inspectionsToMerge = [];

      for (int i = 0; i < pdfFiles.length; i++) {
        final pdfFile = pdfFiles[i];
        final matchingInspection = _mapPdfToInspection(pdfFile, allInspections);
        if (matchingInspection != null) {
          inspectionsToMerge.add(matchingInspection);
        }

        onProgress(i + 1, pdfFiles.length);
      }

      if (inspectionsToMerge.isEmpty) {
        throw Exception('Could not map PDF files to inspections');
      }

      debugPrint(
        'Mapped ${inspectionsToMerge.length} inspections from ${pdfFiles.length} files',
      );

      final clubbedPdfBytes = await PdfService.generateClubbedInspectionPdf(
        inspectionsToMerge,
      );
      return clubbedPdfBytes;
    } catch (e) {
      debugPrint('Error generating clubbed PDF from files: $e');
      rethrow;
    }
  }

  /// Maps a PDF file to an Inspection record based on filename (date) and directory (vehicle)
  static Inspection? _mapPdfToInspection(
    File pdfFile,
    List<Inspection> allInspections,
  ) {
    try {
      final filename = pdfFile.path.split('/').last;
      final pathParts = pdfFile.path.split('/');

      // Filename pattern: Inspection_yyyyMMdd_HHmm.pdf
      final match = RegExp(
        r'Inspection_(\d{8})_(\d{4})\.pdf',
      ).firstMatch(filename);
      if (match == null) return null;

      final dateStr = match.group(1)!;
      final timeStr = match.group(2)!;

      final targetDate = DateTime(
        int.parse(dateStr.substring(0, 4)),
        int.parse(dateStr.substring(4, 6)),
        int.parse(dateStr.substring(6, 8)),
        int.parse(timeStr.substring(0, 2)),
        int.parse(timeStr.substring(2, 4)),
      );

      // Vehicle reg is expected in the parent directory of the PDF
      String? targetVehicleReg;
      if (pathParts.length >= 2) {
        targetVehicleReg = pathParts[pathParts.length - 2];
      }

      return allInspections.where((insp) {
        // Match vehicle first if possible
        if (targetVehicleReg != null) {
          final sanitizedReg = _sanitize(insp.vehicleRegistrationNo);
          if (sanitizedReg != targetVehicleReg) return false;
        }

        // Match date within 1 hour tolerance
        final diff = insp.inspectionDate.difference(targetDate).inMinutes.abs();
        return diff < 60;
      }).firstOrNull;
    } catch (e) {
      debugPrint('Error mapping PDF to inspection: $e');
      return null;
    }
  }
  static Future<void> zipAndShareFolder(Directory dir) async {
    try {
      final zipEncoder = ZipFileEncoder();
      final zipPath = '${dir.path}.zip';
      zipEncoder.zipDirectory(dir, filename: zipPath);
      
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await Share.shareXFiles(
          [XFile(zipPath)], 
          text: 'Shared from Offline Drive: ${dir.path.split('/').last}'
        );
      }
    } catch (e) {
      debugPrint('Error zipping folder: $e');
      rethrow;
    }
  }

  /// Search for a specific vehicle folder across all stores for a given date (month/year)
  static Future<Directory?> findVehicleFolder(String vehicleReg, {int? year, String? month}) async {
    if (_rootDir == null) await init();
    if (_rootDir == null) return null;

    final targetReg = _sanitize(vehicleReg).toLowerCase();
    
    // Default to current date if not provided
    final searchYear = year ?? DateTime.now().year;
    final searchMonth = month ?? DateFormat('MMMM').format(DateTime.now());

    try {
      final stores = await _rootDir!.list().toList();
      for (final storeEntity in stores) {
        if (storeEntity is Directory) {
           // Path: Store/Year/Month/Vehicle
           final potentialPath = '${storeEntity.path}/$searchYear/$searchMonth';
           final monthDir = Directory(potentialPath);
           
           if (await monthDir.exists()) {
             final vehicles = await monthDir.list().toList();
             for (final v in vehicles) {
               if (v is Directory && v.path.split('/').last.toLowerCase().contains(targetReg)) {
                 return v;
               }
             }
           }
        }
      }
    } catch (e) {
      debugPrint('Error searching for vehicle folder: $e');
    }
    return null;
  }
  static Future<void> clearOfflineDrive() async {
    if (_rootDir == null) await init();
    if (_rootDir != null && await _rootDir!.exists()) {
      await _rootDir!.delete(recursive: true);
      await init(); // Re-init to create root folder
    }
  }

  static List<Driver> _getDriversForStore(String storeId, List<Driver> allDrivers) {
    // 1. Mandatory assignment based on store ID (Redwoods vs Koutu)
    if (storeId == 'store_2') {
        // Redwoods drivers
        return allDrivers.where((d) => d.id.startsWith('driver_r')).toList();
    } else if (storeId == 'store_1') {
        // Koutu drivers
        return allDrivers.where((d) => d.id.startsWith('driver_k')).toList();
    }

    // 2. Fallback to history if it's a dynamic store
    final inspections = DatabaseService.getAllInspections();
    final driverIds = inspections
        .where((i) => i.storeId == storeId && i.driverId != null)
        .map((i) => i.driverId)
        .toSet();
    
    final storeDrivers = allDrivers.where((d) => driverIds.contains(d.id)).toList();
    return storeDrivers;
  }
}
