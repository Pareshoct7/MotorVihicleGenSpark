import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/inspection.dart';

/// Service for generating Word documents and PDFs using Python backend
/// 
/// This service uses a Python script to:
/// 1. Fill in a Word template with inspection data
/// 2. Convert the filled Word document to PDF
/// 
/// The Python backend provides better Word document manipulation
/// than native Flutter packages.
class WordPdfService {
  static const String _pythonScript = 'python_services/word_pdf_generator.py';
  static const String _templatePath = 'assets/inspection_template.docx';
  
  /// Generate Word document from inspection data
  /// 
  /// Returns the path to the generated Word document
  static Future<String> generateWordDocument(Inspection inspection) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final outputBase = '${tempDir.path}/inspection_${inspection.vehicleRegistrationNo}_$timestamp';
    
    // Convert inspection to JSON
    final inspectionJson = _inspectionToJson(inspection);
    final jsonPath = '$outputBase.json';
    
    // Write JSON to temp file
    final jsonFile = File(jsonPath);
    await jsonFile.writeAsString(jsonEncode(inspectionJson));
    
    // Get template path
    final templatePath = await _getTemplatePath();
    
    // Run Python script to generate Word document
    final result = await Process.run(
      'python3',
      [
        _pythonScript,
        '--template', templatePath,
        '--inspection-json', jsonPath,
        '--output', outputBase,
        '--word-only',
      ],
    );
    
    if (result.exitCode != 0) {
      throw Exception('Failed to generate Word document: ${result.stderr}');
    }
    
    final wordPath = '$outputBase.docx';
    
    // Clean up JSON file
    await jsonFile.delete();
    
    return wordPath;
  }
  
  /// Generate PDF from inspection data (via Word template)
  /// 
  /// Returns the path to the generated PDF
  static Future<String> generatePdfDocument(Inspection inspection) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final outputBase = '${tempDir.path}/inspection_${inspection.vehicleRegistrationNo}_$timestamp';
    
    // Convert inspection to JSON
    final inspectionJson = _inspectionToJson(inspection);
    final jsonPath = '$outputBase.json';
    
    // Write JSON to temp file
    final jsonFile = File(jsonPath);
    await jsonFile.writeAsString(jsonEncode(inspectionJson));
    
    // Get template path
    final templatePath = await _getTemplatePath();
    
    // Run Python script to generate both Word and PDF
    final result = await Process.run(
      'python3',
      [
        _pythonScript,
        '--template', templatePath,
        '--inspection-json', jsonPath,
        '--output', outputBase,
      ],
    );
    
    if (result.exitCode != 0) {
      throw Exception('Failed to generate PDF: ${result.stderr}');
    }
    
    final pdfPath = '$outputBase.pdf';
    
    // Clean up JSON file
    await jsonFile.delete();
    
    return pdfPath;
  }
  
  /// Share inspection as PDF using Word template
  static Future<void> shareInspection(Inspection inspection) async {
    try {
      final pdfPath = await generatePdfDocument(inspection);
      final pdfFile = File(pdfPath);
      final pdfBytes = await pdfFile.readAsBytes();
      
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'inspection_${inspection.vehicleRegistrationNo}_${DateFormat('yyyyMMdd').format(inspection.inspectionDate)}.pdf',
      );
      
      // Clean up temp file
      await pdfFile.delete();
    } catch (e) {
      throw Exception('Failed to share inspection: $e');
    }
  }
  
  /// Print inspection using Word template
  static Future<void> printInspection(Inspection inspection) async {
    try {
      final pdfPath = await generatePdfDocument(inspection);
      final pdfFile = File(pdfPath);
      final pdfBytes = await pdfFile.readAsBytes();
      
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
      
      // Clean up temp file
      await pdfFile.delete();
    } catch (e) {
      throw Exception('Failed to print inspection: $e');
    }
  }
  
  /// Get the path to the Word template
  static Future<String> _getTemplatePath() async {
    // In production, this would come from assets
    // For now, use the uploaded template
    return '/home/user/assets/inspection_template.docx';
  }
  
  /// Convert Inspection object to JSON for Python script
  static Map<String, dynamic> _inspectionToJson(Inspection inspection) {
    return {
      'vehicleRegistrationNo': inspection.vehicleRegistrationNo,
      'storeName': inspection.storeName,
      'odometerReading': inspection.odometerReading,
      'inspectionDate': inspection.inspectionDate.toIso8601String(),
      'employeeName': inspection.employeeName,
      
      // Checklist items
      'tyresTreadDepth': inspection.tyresTreadDepth ?? false,
      'wheelNuts': inspection.wheelNuts ?? false,
      'cleanliness': inspection.cleanliness ?? false,
      'bodyDamage': inspection.bodyDamage ?? false,
      'mirrorsWindows': inspection.mirrorsWindows ?? false,
      'signage': inspection.signage ?? false,
      'engineOilWater': inspection.engineOilWater ?? false,
      'brakes': inspection.brakes ?? false,
      'transmission': inspection.transmission ?? false,
      'tailLights': inspection.tailLights ?? false,
      'headlightsLowBeam': inspection.headlightsLowBeam ?? false,
      'headlightsHighBeam': inspection.headlightsHighBeam ?? false,
      'reverseLights': inspection.reverseLights ?? false,
      'brakeLights': inspection.brakeLights ?? false,
      'windscreenWipers': inspection.windscreenWipers ?? false,
      'horn': inspection.horn ?? false,
      'indicators': inspection.indicators ?? false,
      'seatBelts': inspection.seatBelts ?? false,
      'cabCleanliness': inspection.cabCleanliness ?? false,
      'serviceLogBook': inspection.serviceLogBook ?? false,
      'spareKeys': inspection.spareKeys ?? false,
      
      // Additional fields
      'bodyDamageNotes': inspection.bodyDamageNotes ?? '',
      'correctiveActions': inspection.correctiveActions ?? '',
      'signature': inspection.signature ?? '',
    };
  }
}
