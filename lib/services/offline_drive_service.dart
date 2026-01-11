import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/inspection.dart';
import '../models/store.dart';
import '../models/driver.dart';
import 'database_service.dart';
import 'pdf_service.dart';
import 'bulk_inspection_service.dart';

class OfflineDriveService {
  static Directory? _rootDir;

  static Future<void> init() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _rootDir = Directory('${appDocDir.path}/OfflineDrive');
      if (!await _rootDir!.exists()) {
        await _rootDir!.create(recursive: true);
      }
      debugPrint('Offline Drive Initialized at: ${_rootDir!.path}');
    } catch (e) {
      debugPrint('Error initializing Offline Drive: $e');
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
      // We assume vehicle.odometerReading is CURRENT.
      final int baseOdometer = vehicle.odometerReading ?? 0;
      final odometerMap = BulkInspectionService.calculateBackdatedOdometers(
        weeksBack: weeksBack,
        baseOdometer: baseOdometer,
        anchorDate: DateTime.now(),
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

          inspection = BulkInspectionService.generateInspection(
            vehicle: vehicle,
            store: store,
            driver: driver,
            date: date,
            odometer: odometer,
          );

          await DatabaseService.addInspection(inspection);
        } else {
          // Fetch existing (we need it to save PDF)
          // This is expensive: iterating all inspections to find one.
          // Optimize? getAllInspections() is cached by Hive effectively, but parsing filtering is linear.
          // For backfill script, it's okay.
          try {
            final all = DatabaseService.getAllInspections();
            inspection = all.firstWhere(
              (i) =>
                  i.vehicleId == vehicle.id &&
                  _isSameWeek(i.inspectionDate, date),
            );
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
}
