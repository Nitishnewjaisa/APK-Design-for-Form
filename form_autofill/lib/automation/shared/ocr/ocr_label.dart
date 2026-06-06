/// OCR-extracted label with bounding coordinates.
class OcrLabel {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final int confidence;
  final String? matchedFieldKey;

  const OcrLabel({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 0,
    this.matchedFieldKey,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'confidence': confidence,
        if (matchedFieldKey != null) 'matchedFieldKey': matchedFieldKey,
      };

  factory OcrLabel.fromJson(Map<String, dynamic> json) => OcrLabel(
        text: json['text'] as String? ?? '',
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        width: (json['width'] as num?)?.toDouble() ?? 0,
        height: (json['height'] as num?)?.toDouble() ?? 0,
        confidence: json['confidence'] as int? ?? 0,
        matchedFieldKey: json['matchedFieldKey'] as String?,
      );
}
