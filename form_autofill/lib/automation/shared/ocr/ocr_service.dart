import 'ocr_label.dart';

/// Cross-platform OCR contract (Android ML Kit, Tesseract desktop/web).
abstract class OcrService {
  Future<List<OcrLabel>> extractLabels({
    required String imagePath,
    int minConfidence = 65,
  });

  Future<List<OcrLabel>> extractLabelsFromBytes({
    required List<int> bytes,
    int minConfidence = 65,
  });

  Future<void> dispose();
}
