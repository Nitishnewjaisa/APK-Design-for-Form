import 'dart:async';

import '../../domain/entities/debug_log_entry.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_datasource.dart';

class LogRepositoryImpl implements LogRepository {
  final LogLocalDatasource _datasource;
  final _controller = StreamController<List<DebugLogEntry>>.broadcast();

  LogRepositoryImpl(this._datasource);

  void _emit() => _controller.add(_datasource.getLogs());

  @override
  Stream<List<DebugLogEntry>> watchLogs() {
    _emit();
    return _controller.stream;
  }

  @override
  Future<void> addLog(DebugLogEntry entry) async {
    await _datasource.add(entry);
    _emit();
  }

  @override
  Future<void> clearLogs() async {
    await _datasource.clear();
    _emit();
  }

  @override
  Future<List<DebugLogEntry>> getLogs() async => _datasource.getLogs();
}
