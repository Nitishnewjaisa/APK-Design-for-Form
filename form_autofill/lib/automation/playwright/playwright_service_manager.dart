import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/process_run.dart';

/// Starts/stops the Node.js Playwright sidecar process.
class PlaywrightServiceManager {
  Process? _process;
  final String projectRoot;

  PlaywrightServiceManager({required this.projectRoot});

  String get serviceDir => p.join(projectRoot, 'automation', 'playwright');

  Future<bool> ensureRunning() async {
    final client = HttpClient();
    try {
      final req = await client
          .getUrl(Uri.parse('http://127.0.0.1:3939/health'))
          .timeout(const Duration(seconds: 2));
      final res = await req.close();
      client.close();
      return res.statusCode == 200;
    } catch (_) {
      client.close();
    }

    if (!await _startProcess()) return false;
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      try {
        final c = HttpClient();
        final req = await c.getUrl(Uri.parse('http://127.0.0.1:3939/health'));
        final res = await req.close();
        c.close();
        if (res.statusCode == 200) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> _startProcess() async {
    if (_process != null) return true;
    final serverPath = p.join(serviceDir, 'src', 'server.mjs');
    if (!File(serverPath).existsSync()) return false;

    final shell = Platform.isWindows ? 'cmd' : 'bash';
    final args = Platform.isWindows
        ? ['/c', 'node', serverPath]
        : ['-c', 'node "$serverPath"'];

    _process = await Process.start(
      shell,
      args,
      workingDirectory: serviceDir,
      mode: ProcessStartMode.detached,
    );
    return true;
  }

  Future<void> stop() async {
    _process?.kill();
    _process = null;
  }
}
