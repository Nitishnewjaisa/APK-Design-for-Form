import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/form_profile.dart';

class ProfileLocalDatasource {
  static const _profilesKey = 'profiles';
  static const _activeIdKey = 'active_profile_id';

  final Box _box;

  ProfileLocalDatasource(this._box);

  Future<List<FormProfile>> getAll() async {
    final raw = _box.get(_profilesKey);
    if (raw is! List) return [];
    return raw
        .map((e) => _fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<FormProfile?> getActive() async {
    final activeId = _box.get(_activeIdKey) as String?;
    if (activeId == null) return null;
    final profiles = await getAll();
    try {
      return profiles.firstWhere((p) => p.id == activeId);
    } catch (_) {
      return profiles.isNotEmpty ? profiles.first : null;
    }
  }

  Future<void> save(FormProfile profile) async {
    final profiles = await getAll();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await _box.put(
      _profilesKey,
      profiles.map(_toMap).toList(),
    );
  }

  Future<void> delete(String id) async {
    final profiles = await getAll();
    profiles.removeWhere((p) => p.id == id);
    await _box.put(_profilesKey, profiles.map(_toMap).toList());
    if (_box.get(_activeIdKey) == id && profiles.isNotEmpty) {
      await _box.put(_activeIdKey, profiles.first.id);
    } else if (profiles.isEmpty) {
      await _box.delete(_activeIdKey);
    }
  }

  Future<void> setActive(String id) async {
    await _box.put(_activeIdKey, id);
  }

  Map<String, dynamic> _toMap(FormProfile p) => {
        'id': p.id,
        'name': p.name,
        'fields': p.fields,
        'updatedAt': p.updatedAt.toIso8601String(),
      };

  FormProfile _fromMap(Map<String, dynamic> m) => FormProfile(
        id: m['id'] as String,
        name: m['name'] as String,
        fields: Map<String, String>.from(
          (m['fields'] as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ),
        ),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}
