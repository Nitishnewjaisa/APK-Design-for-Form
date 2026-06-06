import 'ocr_label.dart';
import 'ocr_service.dart';

/// Coordinates multiple OCR backends and merges label results.
class HybridOcrCoordinator {
  final List<OcrService> backends;

  HybridOcrCoordinator(this.backends);

  Future<List<OcrLabel>> extractBest({
    required String imagePath,
    int minConfidence = 65,
  }) async {
    final merged = <String, OcrLabel>{};
    for (final backend in backends) {
      try {
        final labels = await backend.extractLabels(
          imagePath: imagePath,
          minConfidence: minConfidence,
        );
        for (final label in labels) {
          final key = '${label.text}_${label.x.round()}_${label.y.round()}';
          final existing = merged[key];
          if (existing == null || label.confidence > existing.confidence) {
            merged[key] = label;
          }
        }
      } catch (_) {
        // Continue with next backend
      }
    }
    return merged.values.toList();
  }

  Future<void> dispose() async {
    for (final b in backends) {
      await b.dispose();
    }
  }
}
