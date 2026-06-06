import 'dart:convert';
import 'dart:io';

import 'package:process_run/process_run.dart';

import '../label_matcher.dart';
import 'ocr_label.dart';
import 'ocr_service.dart';

/// Tesseract CLI adapter for Windows / macOS / Linux / Web server sidecar.
class TesseractOcrAdapter implements OcrService {
  final String tesseractExecutable;

  TesseractOcrAdapter({this.tesseractExecutable = 'tesseract'});

  @override
  Future<List<OcrLabel>> extractLabels({
    required String imagePath,
    int minConfidence = 65,
  }) async {
    if (!File(imagePath).existsSync()) return [];
    final result = await runExecutableArguments(
      tesseractExecutable,
      [imagePath, 'stdout', '-l', 'eng', 'tsv'],
      stdoutEncoding: utf8,
    );
    return _parseTsv(result.stdout.toString(), minConfidence);
  }

  @override
  Future<List<OcrLabel>> extractLabelsFromBytes({
    required List<int> bytes,
    int minConfidence = 65,
  }) async {
    final temp = File(
      '${Directory.systemTemp.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await temp.writeAsBytes(bytes);
    try {
      return await extractLabels(imagePath: temp.path, minConfidence: minConfidence);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  List<OcrLabel> _parseTsv(String tsv, int minConfidence) {
    final lines = tsv.split('\n');
    if (lines.length < 2) return [];
    final labels = <OcrLabel>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split('\t');
      if (cols.length < 12) continue;
      final conf = int.tryParse(cols[10]) ?? 0;
      if (conf < minConfidence) continue;
      final text = cols[11].trim();
      if (text.length < 2) continue;
      final x = double.tryParse(cols[6]) ?? 0;
      final y = double.tryParse(cols[7]) ?? 0;
      final w = double.tryParse(cols[8]) ?? 0;
      final h = double.tryParse(cols[9]) ?? 0;
      labels.add(
        OcrLabel(
          text: text,
          x: x,
          y: y,
          width: w,
          height: h,
          confidence: conf,
          matchedFieldKey: LabelMatcher.matchLabel(text, minScore: minConfidence),
        ),
      );
    }
    return labels;
  }

  @override
  Future<void> dispose() async {}
}
