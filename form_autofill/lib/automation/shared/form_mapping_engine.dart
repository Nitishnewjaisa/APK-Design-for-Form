import 'label_matcher.dart';

/// Detected field with optional screen coordinates (OCR / layout).
class MappedField {
  final String key;
  final String value;
  final String label;
  final bool isDropdown;
  final bool isFileInput;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final String? selector;

  const MappedField({
    required this.key,
    required this.value,
    required this.label,
    this.isDropdown = false,
    this.isFileInput = false,
    this.x,
    this.y,
    this.width,
    this.height,
    this.selector,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'label': label,
        'isDropdown': isDropdown,
        'isFileInput': isFileInput,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (selector != null) 'selector': selector,
      };
}

/// Platform-independent field mapping from labels + candidate inputs.
class FormMappingEngine {
  final Map<String, String> fieldData;

  const FormMappingEngine(this.fieldData);

  List<MappedField> mapFromCandidates({
    required List<LabelCandidate> labels,
    required List<InputCandidate> inputs,
  }) {
    final results = <MappedField>[];
    final usedKeys = <String>{};

    for (final input in inputs) {
      final hints = [
        input.hint,
        input.ariaLabel,
        input.name,
        input.id,
        input.placeholder,
        _nearestLabel(input, labels),
      ].where((e) => e != null && e!.trim().isNotEmpty).cast<String>();

      String? matchedKey;
      String matchedLabel = '';
      for (final candidate in hints) {
        matchedKey = LabelMatcher.matchLabel(candidate);
        if (matchedKey != null) {
          matchedLabel = candidate;
          break;
        }
      }

      if (matchedKey == null || usedKeys.contains(matchedKey)) continue;
      final value = fieldData[matchedKey];
      if (value == null || value.isEmpty) continue;

      results.add(
        MappedField(
          key: matchedKey,
          value: value,
          label: matchedLabel.isNotEmpty ? matchedLabel : matchedKey,
          isDropdown: input.isDropdown,
          isFileInput: input.isFileInput,
          x: input.x,
          y: input.y,
          width: input.width,
          height: input.height,
          selector: input.selector,
        ),
      );
      usedKeys.add(matchedKey);
    }
    return results;
  }

  String _nearestLabel(InputCandidate input, List<LabelCandidate> labels) {
    if (input.y == null) return '';
    var best = '';
    var bestDist = double.infinity;
    for (final label in labels) {
      if (label.y == null) continue;
      final dy = (input.y! - label.y!).abs();
      final dx = input.x != null && label.x != null
          ? (input.x! - label.x!).abs()
          : 0.0;
      final dist = dy + dx;
      if (dist < bestDist) {
        bestDist = dist;
        best = label.text;
      }
    }
    return best;
  }
}

class LabelCandidate {
  final String text;
  final double? x;
  final double? y;
  final double? width;
  final double? height;

  const LabelCandidate({
    required this.text,
    this.x,
    this.y,
    this.width,
    this.height,
  });
}

class InputCandidate {
  final String? hint;
  final String? ariaLabel;
  final String? name;
  final String? id;
  final String? placeholder;
  final bool isDropdown;
  final bool isFileInput;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final String? selector;

  const InputCandidate({
    this.hint,
    this.ariaLabel,
    this.name,
    this.id,
    this.placeholder,
    this.isDropdown = false,
    this.isFileInput = false,
    this.x,
    this.y,
    this.width,
    this.height,
    this.selector,
  });
}
