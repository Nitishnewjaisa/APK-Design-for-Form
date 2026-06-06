import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/automation_status.dart';
import '../../domain/entities/debug_log_entry.dart';

class DebugPanelPage extends StatelessWidget {
  final List<DebugLogEntry> logs;
  final AutomationStatus status;
  final Future<void> Function() onClear;

  const DebugPanelPage({
    super.key,
    required this.logs,
    required this.status,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm:ss');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Debug Logs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: logs.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: ListTile(
              dense: true,
              title: Text('State: ${status.state.name}'),
              subtitle: Text(status.message.isEmpty ? '—' : status.message),
            ),
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? const Center(child: Text('No logs yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _LogTile(log: log, timeFmt: timeFmt);
                  },
                ),
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final DebugLogEntry log;
  final DateFormat timeFmt;

  const _LogTile({required this.log, required this.timeFmt});

  @override
  Widget build(BuildContext context) {
    final color = switch (log.level) {
      LogLevel.error => Colors.red,
      LogLevel.warning => Colors.orange,
      LogLevel.info => Colors.blue,
      LogLevel.debug => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 6),
                Text(
                  log.tag,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  timeFmt.format(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(log.message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
