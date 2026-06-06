import 'dart:convert';
import 'dart:io';

import '../../automation/shared/form_data_engine.dart';
import '../../domain/entities/form_profile.dart';

/// Import/export JSON profiles (platform-independent).
class JsonProfileDatasource {
  Future<FormProfile> importFromFile(String path) async {
    final content = await File(path).readAsString();
    return importFromString(content);
  }

  FormProfile importFromString(String json) {
    final map = FormDataEngine.decodeProfile(json);
    final fields = FormDataEngine.fromJsonMap(map);
    return FormProfile(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? 'Imported Profile',
      fields: fields,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> exportToFile(FormProfile profile, String path) async {
    final json = exportToString(profile);
    await File(path).writeAsString(json);
  }

  String exportToString(FormProfile profile) {
    final map = FormDataEngine.toProfileJson(
      id: profile.id,
      name: profile.name,
      fields: profile.fields,
      updatedAt: profile.updatedAt,
    );
    return FormDataEngine.encodeProfile(map);
  }

  /// Example template for users.
  static String exampleTemplate() {
    return const JsonEncoder.withIndent('  ').convert({
      'name': 'My Form Profile',
      'fields': {
        'full_name': '',
        'father_name': '',
        'mother_name': '',
        'gender': '',
        'address': '',
        'dob': '',
        'district': '',
      },
    });
  }
}
