import '../entities/debug_log_entry.dart';

abstract class LogRepository {
  Stream<List<DebugLogEntry>> watchLogs();
  Future<void> addLog(DebugLogEntry entry);
  Future<void> clearLogs();
  Future<List<DebugLogEntry>> getLogs();
}
