import 'dart:async';

import '../../../domain/entities/automation_status.dart';
import '../android/android_automation_adapter.dart';
import '../playwright/playwright_automation_adapter.dart';
import '../windows/windows_automation_adapter.dart';
import 'automation_adapter.dart';
import 'automation_platform_type.dart';
import 'automation_session_config.dart';

/// Routes automation sessions to the correct platform adapter.
class AutomationOrchestrator {
  final Map<AutomationPlatformType, AutomationAdapter> _adapters;
  AutomationAdapter? _active;
  final _statusController = StreamController<AutomationStatus>.broadcast();

  AutomationOrchestrator({
    AndroidAutomationAdapter? android,
    PlaywrightAutomationAdapter? playwright,
    WindowsAutomationAdapter? windows,
  }) : _adapters = {
          AutomationPlatformType.android: android ?? AndroidAutomationAdapter(),
          AutomationPlatformType.browser:
              playwright ?? PlaywrightAutomationAdapter(),
          AutomationPlatformType.web:
              playwright ?? PlaywrightAutomationAdapter(),
          AutomationPlatformType.hybridOcr:
              playwright ?? PlaywrightAutomationAdapter(),
          AutomationPlatformType.windows:
              windows ?? WindowsAutomationAdapter(),
        };

  Stream<AutomationStatus> get statusStream => _statusController.stream;

  AutomationPlatformType? get activePlatform => _active?.platformType;

  AutomationAdapter adapterFor(AutomationPlatformType type) {
    return _adapters[type.resolvedRuntime]!;
  }

  Future<bool> isAvailable(AutomationPlatformType type) =>
      adapterFor(type).isAvailable();

  Future<void> start(AutomationSessionConfig config) async {
    await stop();
    final runtime = config.platform.resolvedRuntime;
    if (config.platform == AutomationPlatformType.hybridOcr) {
      _active = _HybridOcrAdapter(
        primary: _adapters[AutomationPlatformType.browser]!,
        fallback: _adapters[AutomationPlatformType.android]!,
      );
    } else {
      _active = _adapters[runtime];
    }
    await _active!.prepareEnvironment();
    _active!.statusStream.listen(_statusController.add);
    await _active!.start(config);
  }

  Future<void> stop() async {
    await _active?.stop();
    _active = null;
  }

  Future<void> pause() => _active?.pause() ?? Future.value();

  Future<void> resume() => _active?.resume() ?? Future.value();

  // Android-only convenience (preserved API)
  Future<bool> isAccessibilityEnabled() {
    final android = _adapters[AutomationPlatformType.android];
    if (android is AndroidAutomationAdapter) {
      return android.isAccessibilityEnabled();
    }
    return Future.value(false);
  }

  Future<bool> isOverlayGranted() {
    final android = _adapters[AutomationPlatformType.android];
    if (android is AndroidAutomationAdapter) {
      return android.isOverlayGranted();
    }
    return Future.value(true);
  }

  Future<void> openAccessibilitySettings() {
    final android = _adapters[AutomationPlatformType.android];
    if (android is AndroidAutomationAdapter) {
      return android.openAccessibilitySettings();
    }
    return Future.value();
  }

  Future<void> openOverlaySettings() {
    final android = _adapters[AutomationPlatformType.android];
    if (android is AndroidAutomationAdapter) {
      return android.openOverlaySettings();
    }
    return Future.value();
  }

  void dispose() {
    _statusController.close();
  }
}

/// Hybrid: browser Playwright with OCR assist + Android fallback when on mobile.
class _HybridOcrAdapter implements AutomationAdapter {
  final AutomationAdapter primary;
  final AutomationAdapter fallback;
  StreamSubscription<AutomationStatus>? _sub;

  _HybridOcrAdapter({required this.primary, required this.fallback});

  @override
  AutomationPlatformType get platformType => AutomationPlatformType.hybridOcr;

  @override
  Stream<AutomationStatus> get statusStream => primary.statusStream;

  @override
  Future<bool> isAvailable() async =>
      (await primary.isAvailable()) || (await fallback.isAvailable());

  @override
  Future<void> prepareEnvironment() async {
    if (await primary.isAvailable()) {
      await primary.prepareEnvironment();
    } else {
      await fallback.prepareEnvironment();
    }
  }

  @override
  Future<void> start(AutomationSessionConfig config) async {
    final hybridConfig = AutomationSessionConfig(
      platform: config.platform,
      fieldData: config.fieldData,
      targetUrl: config.targetUrl,
      browser: config.browser,
      uploadPaths: config.uploadPaths,
      maxScrollRetries: config.maxScrollRetries,
      scrollDelayMs: config.scrollDelayMs,
      retryDelayMs: config.retryDelayMs,
      ocrThreshold: config.ocrThreshold,
      useOcrAssist: true,
    );
    if (await primary.isAvailable()) {
      await primary.start(hybridConfig);
    } else {
      await fallback.start(hybridConfig);
    }
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    await primary.stop();
    await fallback.stop();
  }

  @override
  Future<void> pause() => primary.pause();

  @override
  Future<void> resume() => primary.resume();
}
