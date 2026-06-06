import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../android/android_ocr_adapter.dart';
import 'hybrid_ocr_coordinator.dart';
import 'ocr_service.dart';
import 'tesseract_ocr_adapter.dart';

/// Creates the best OCR backend for the current platform.
class OcrServiceFactory {
  static OcrService create({String? tesseractPath}) {
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidOcrAdapter();
    }
    return TesseractOcrAdapter(tesseractExecutable: tesseractPath ?? 'tesseract');
  }

  static HybridOcrCoordinator createHybrid({String? tesseractPath}) {
    final backends = <OcrService>[];
    if (!kIsWeb && Platform.isAndroid) {
      backends.add(AndroidOcrAdapter());
    }
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      backends.add(TesseractOcrAdapter(tesseractExecutable: tesseractPath ?? 'tesseract'));
    }
    return HybridOcrCoordinator(backends);
  }
}
