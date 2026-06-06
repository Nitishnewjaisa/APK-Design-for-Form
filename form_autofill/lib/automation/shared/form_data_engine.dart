import 'dart:convert';

/// JSON-driven, platform-independent form profile data engine.
class FormDataEngine {
  static const List<String> standardKeys = [
    'full_name',
    'father_name',
    'mother_name',
    'gender',
    'address',
    'dob',
    'district',
    'email',
    'phone',
    'pincode',
    'state',
    'city',
    'aadhaar',
    'pan',
  ];

  /// Canonical empty profile template.
  static Map<String, String> emptyTemplate() => {
        for (final k in standardKeys) k: '',
      };

  static Map<String, String> fromJsonMap(Map<String, dynamic> json) {
    final fields = <String, String>{};
    final raw = json['fields'];
    if (raw is Map) {
      raw.forEach((key, value) {
        final k = key.toString();
        final v = value?.toString().trim() ?? '';
        if (v.isNotEmpty) fields[k] = v;
      });
    } else {
      for (final key in standardKeys) {
        final v = json[key]?.toString().trim() ?? '';
        if (v.isNotEmpty) fields[key] = v;
      }
    }
    return fields;
  }

  static Map<String, dynamic> toProfileJson({
    required String id,
    required String name,
    required Map<String, String> fields,
    DateTime? updatedAt,
  }) =>
      {
        'id': id,
        'name': name,
        'fields': fields,
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
        'schemaVersion': 1,
      };

  static String encodeProfile(Map<String, dynamic> profile) =>
      const JsonEncoder.withIndent('  ').convert(profile);

  static Map<String, dynamic> decodeProfile(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  static Map<String, String> merge(
    Map<String, String> base,
    Map<String, String> override,
  ) {
    final merged = Map<String, String>.from(base);
    override.forEach((k, v) {
      if (v.trim().isNotEmpty) merged[k] = v.trim();
    });
    return merged;
  }
}
