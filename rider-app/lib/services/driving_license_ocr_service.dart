import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of OCR extraction & validation
class DrivingLicenseOcrResult {
  final String extractedNumber;
  final String rawText;
  final bool isValidFormat;
  final String status;
  final String message;

  DrivingLicenseOcrResult({
    required this.extractedNumber,
    required this.rawText,
    required this.isValidFormat,
    required this.status,
    required this.message,
  });

  factory DrivingLicenseOcrResult.failed(String msg, {String raw = ''}) {
    return DrivingLicenseOcrResult(
      extractedNumber: '',
      rawText: raw,
      isValidFormat: false,
      status: 'extraction_failed',
      message: msg,
    );
  }
}

class DrivingLicenseOcrService {
  /// Extract DL number from an image at [imagePath]
  static Future<DrivingLicenseOcrResult> extractFromImage(String imagePath) async {
    if (imagePath.trim().isEmpty) {
      return DrivingLicenseOcrResult.failed('No image path provided.');
    }

    TextRecognizer? textRecognizer;
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      final String fullText = recognizedText.text;
      debugPrint('[DL OCR Service] Raw OCR text extracted:\n$fullText');

      if (fullText.trim().isEmpty) {
        return DrivingLicenseOcrResult.failed('No text detected in the image. Please try a clearer photo.', raw: fullText);
      }

      final candidate = parseAndNormalizeDlNumber(fullText);
      if (candidate.isEmpty) {
        return DrivingLicenseOcrResult.failed(
          'Could not auto-detect a valid Driving Licence number format. Please enter it manually.',
          raw: fullText,
        );
      }

      final isValid = validateIndianDlFormat(candidate);
      return DrivingLicenseOcrResult(
        extractedNumber: candidate,
        rawText: fullText,
        isValidFormat: isValid,
        status: isValid ? 'needs_confirmation' : 'invalid_format',
        message: isValid
            ? 'Licence number detected! Please confirm or edit.'
            : 'Extracted number candidate ($candidate) has unusual format. Please verify.',
      );
    } catch (e) {
      debugPrint('[DL OCR Service] OCR process error: $e');
      return DrivingLicenseOcrResult.failed(
        'Could not process image with OCR. Please enter your DL number manually.',
      );
    } finally {
      await textRecognizer?.close();
    }
  }

  /// Parse raw OCR text to find candidate Indian DL Number
  static String parseAndNormalizeDlNumber(String text) {
    if (text.isEmpty) return '';

    // Standard Indian DL regex pattern:
    // E.g., MH1420260012345 or DL-0420191234567 or KA 01 2018 0001234
    // 2-letter state code + 2 digits (RTO) + 4 digits (Year) + 7 digits
    final lines = text.split(RegExp(r'[\r\n]+'));

    // Regex 1: Exact 15-char DL pattern (State + RTO + Year + 7 digits)
    final strictDlRegex = RegExp(r'\b([A-Za-z]{2}[\s\-]?[0-9]{2}[\s\-]?[0-9]{4}[\s\-]?[0-9]{7})\b');
    for (final line in lines) {
      final match = strictDlRegex.firstMatch(line);
      if (match != null) {
        return normalizeDlString(match.group(1)!);
      }
    }

    // Regex 2: Flexible DL pattern (State + 11 to 14 alphanumeric chars)
    final flexDlRegex = RegExp(r'\b([A-Za-z]{2}[\s\-]?[0-9A-Za-z\s\-]{11,16})\b');
    for (final line in lines) {
      final cleanLine = line.toUpperCase().trim();
      // Skip lines containing words like "DRIVING", "LICENCE", "INDIA", "TRANSPORT" unless they contain numbers
      if (cleanLine.contains('LICENCE') || cleanLine.contains('GOVERNMENT') || cleanLine.contains('UNION')) {
        continue;
      }

      final match = flexDlRegex.firstMatch(line);
      if (match != null) {
        final candidate = normalizeDlString(match.group(1)!);
        if (candidate.length >= 13 && candidate.length <= 16) {
          return candidate;
        }
      }
    }

    // Regex 3: Global match on whole text after removing linebreaks
    final wholeTextClean = text.replaceAll(RegExp(r'[\r\n]+'), ' ');
    final globalMatch = strictDlRegex.firstMatch(wholeTextClean);
    if (globalMatch != null) {
      return normalizeDlString(globalMatch.group(1)!);
    }

    return '';
  }

  /// Remove spaces, hyphens and convert to uppercase
  static String normalizeDlString(String raw) {
    String cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return cleaned;
  }

  /// Basic format validation for Indian Driving Licence
  /// Format: 2 State chars + 2 RTO digits + 4 Year digits + 7 Serial digits (Total 15 chars)
  /// Or flexible 13 to 16 chars starting with 2 letters.
  static bool validateIndianDlFormat(String dlNumber) {
    final clean = normalizeDlString(dlNumber);

    if (clean.length < 13 || clean.length > 16) return false;

    // Check if starts with 2 letters
    final startsWithStateCode = RegExp(r'^[A-Z]{2}').hasMatch(clean);
    if (!startsWithStateCode) return false;

    // Check strict 15-char Indian DL standard:
    // SS-RR-YYYY-NNNNNNN
    final strictPattern = RegExp(r'^[A-Z]{2}[0-9]{2}[0-9]{4}[0-9]{7}$');
    if (strictPattern.hasMatch(clean)) return true;

    // Flexible Indian DL pattern check (some old DLs have 13 to 16 chars with numbers after state code)
    final flexiblePattern = RegExp(r'^[A-Z]{2}[0-9A-Z]{11,14}$');
    return flexiblePattern.hasMatch(clean);
  }
}
