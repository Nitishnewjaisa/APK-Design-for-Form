import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../domain/entities/automation_status.dart';
import '../shared/automation_adapter.dart';
import '../shared/automation_platform_type.dart';
import '../shared/automation_session_config.dart';
import 'playwright_client.dart';
import 'playwright_service_manager.dart';

/// Browser / web form automation via Playwright sidecar.
class PlaywrightAutomationAdapter implements AutomationAdapter {
  final PlaywrightClient client;
  PlaywrightServiceManager? _serviceManager;
  StreamSubscription<AutomationStatus>? _statusSub;
  final _statusController = StreamController<AutomationStatus>.broadcast();

  PlaywrightAutomationAdapter({PlaywrightClient? client})
      : client = client ?? PlaywrightClient();

  @override
  AutomationPlatformType get platformType => AutomationPlatformType.browser;

  @override
  Stream<AutomationStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  Future<void> prepareEnvironment() async {
    if (!await isAvailable()) return;
    _serviceManager ??= PlaywrightServiceManager(
      projectRoot: _resolveProjectRoot(),
    );
    await _serviceManager!.ensureRunning();
  }

  @override
  Future<void> start(AutomationSessionConfig config) async {
    if (config.targetUrl == null || config.targetUrl!.isEmpty) {
      _statusController.add(
        const AutomationStatus(
          state: AutomationState.error,
          message: 'Target URL is required for browser automation',
        ),
      );
      return;
    }
    await prepareEnvironment();
    if (!await client.healthCheck()) {
      _statusController.add(
        const AutomationStatus(
          state: AutomationState.error,
          message: 'Playwright service not running. Run: npm start in automation/playwright',
        ),
      );
      return;
    }
    await _statusSub?.cancel();
    _statusSub = client.statusStream().listen(_statusController.add);
    await client.start(config);
  }

  @override
  Future<void> stop() async {
    await _statusSub?.cancel();
    await client.stop();
    _statusController.add(
      const AutomationStatus(state: AutomationState.stopped),
    );
  }

  @override
  Future<void> pause() => client.pause();

  @override
  Future<void> resume() => client.resume();

  String _resolveProjectRoot() {
    var dir = Directory.current;
    if (dir.path.endsWith('form_autofill')) return dir.path;
    final candidate = p.join(dir.path, 'form_autofill');
    if (Directory(candidate).existsSync()) return candidate;
    return dir.path;
  }
}
