import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AiScannerService {
  static final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Processes an [InputImage] and returns the extracted text.
  static Future<String?> recognizeText(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('OCR Error: $e');
      return null;
    }
  }

  /// Extracts a potential License Plate from the text.
  /// Standard NZ plate: 3 letters + 3 numbers or custom.
  static String? extractLicensePlate(String text) {
    // Simple NZ Plate Regex (e.g., ABC123 or ABCD12)
    final plateRegex = RegExp(r'\b[A-Z]{2,4}\d{1,4}\b');
    final match = plateRegex.firstMatch(text.toUpperCase());
    return match?.group(0);
  }

  /// Extracts a potential Odometer reading (numeric sequence).
  static String? extractOdometer(String text) {
    // Look for 5-7 digit numbers which are common for odometers
    final odoRegex = RegExp(r'\b\d{4,7}\b');
    final matches = odoRegex.allMatches(text);
    
    // Often the largest number or one matched near "km" is the odometer
    // For now, we take the first 4-7 digit sequence
    if (matches.isNotEmpty) {
      return matches.first.group(0);
    }
    return null;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
