import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/debug_log_entry.dart';

class LogLocalDatasource {
  static const _logsKey = 'logs';
  final Box _box;
  final _uuid = const Uuid();

  LogLocalDatasource(this._box);

  List<DebugLogEntry> getLogs() {
    final raw = _box.get(_logsKey);
    if (raw is! List) return [];
    return raw
        .map((e) => _fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> add(DebugLogEntry entry) async {
    final logs = getLogs().reversed.toList();
    logs.add(entry);
    while (logs.length > AppConstants.maxLogEntries) {
      logs.removeAt(0);
    }
    await _box.put(_logsKey, logs.map(_toMap).toList());
  }

  Future<void> addQuick({
    required LogLevel level,
    required String tag,
    required String message,
  }) async {
    await add(DebugLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    ));
  }

  Future<void> clear() async {
    await _box.put(_logsKey, <Map>[]);
  }

  Map<String, dynamic> _toMap(DebugLogEntry e) => {
        'id': e.id,
        'timestamp': e.timestamp.toIso8601String(),
        'level': e.level.name,
        'tag': e.tag,
        'message': e.message,
      };

  DebugLogEntry _fromMap(Map<String, dynamic> m) => DebugLogEntry(
        id: m['id'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        level: LogLevel.values.byName(m['level'] as String),
        tag: m['tag'] as String,
        message: m['message'] as String,
      );
}
