import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/automation_status.dart';
import '../shared/automation_adapter.dart';
import '../shared/automation_platform_type.dart';
import '../shared/automation_session_config.dart';
import 'win32_automation_bridge.dart';

/// Windows desktop automation adapter (prepared for future Win32/UIA).
class WindowsAutomationAdapter implements AutomationAdapter {
  final Win32AutomationBridge _bridge;
  final _statusController = StreamController<AutomationStatus>.broadcast();

  WindowsAutomationAdapter({Win32AutomationBridge? bridge})
      : _bridge = bridge ?? Win32AutomationBridge();

  @override
  AutomationPlatformType get platformType => AutomationPlatformType.windows;

  @override
  Stream<AutomationStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return Platform.isWindows && await _bridge.isSupported();
  }

  @override
  Future<void> prepareEnvironment() => _bridge.initialize();

  @override
  Future<void> start(AutomationSessionConfig config) async {
    _statusController.add(
      const AutomationStatus(
        state: AutomationState.scanning,
        message: 'Windows desktop automation is in preparation',
      ),
    );
    final result = await _bridge.fillForm(config.fieldData);
    _statusController.add(
      AutomationStatus(
        state: result ? AutomationState.completed : AutomationState.error,
        message: result
            ? 'Windows automation stub completed'
            : 'Win32/UIA bridge not yet implemented — use Browser Automation',
        fieldsFilled: result ? config.fieldData.length : 0,
        fieldsTotal: config.fieldData.length,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _bridge.stop();
    _statusController.add(
      const AutomationStatus(state: AutomationState.stopped),
    );
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}
}
