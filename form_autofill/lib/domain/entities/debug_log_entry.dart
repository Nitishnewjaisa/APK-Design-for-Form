enum LogLevel { debug, info, warning, error }

class DebugLogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  const DebugLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });
}
