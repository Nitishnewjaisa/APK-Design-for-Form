import 'dart:io';

import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../shared/ocr/ocr_label.dart';
import '../shared/ocr/ocr_service.dart';

/// Android ML Kit OCR bridge (existing native layer).
class AndroidOcrAdapter implements OcrService {
  static const _channel = MethodChannel(AppConstants.channelOcr);

  @override
  Future<List<OcrLabel>> extractLabels({
    required String imagePath,
    int minConfidence = 65,
  }) async {
    if (!Platform.isAndroid) return [];
    final result = await _channel.invokeMethod<List<dynamic>>('extractLabels', {
      'imagePath': imagePath,
      'minConfidence': minConfidence,
    });
    return _parse(result);
  }

  @override
  Future<List<OcrLabel>> extractLabelsFromBytes({
    required List<int> bytes,
    int minConfidence = 65,
  }) async {
    if (!Platform.isAndroid) return [];
    final result =
        await _channel.invokeMethod<List<dynamic>>('extractLabelsFromBytes', {
      'bytes': bytes,
      'minConfidence': minConfidence,
    });
    return _parse(result);
  }

  List<OcrLabel> _parse(List<dynamic>? raw) {
    if (raw == null) return [];
    return raw
        .map((e) => OcrLabel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> dispose() async {}
}
