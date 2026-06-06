import 'package:hive_flutter/hive_flutter.dart';

import '../../automation/shared/automation_orchestrator.dart';
import '../../automation/shared/automation_platform_type.dart';
import '../../automation/shared/automation_session_config.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/automation_status.dart';
import '../../domain/entities/debug_log_entry.dart';
import '../../domain/repositories/automation_repository.dart';
import '../datasources/log_local_datasource.dart';

class AutomationRepositoryImpl implements AutomationRepository {
  final AutomationOrchestrator _orchestrator;
  final LogLocalDatasource _logs;
  final Box _prefsBox;

  static const _platformKey = 'selected_platform';
  static const _urlKey = 'target_url';
  static const _browserKey = 'selected_browser';

  AutomationRepositoryImpl(this._orchestrator, this._logs, this._prefsBox);

  @override
  Stream<AutomationStatus> get statusStream => _orchestrator.statusStream;

  @override
  AutomationPlatformType get selectedPlatform =>
      AutomationPlatformType.fromId(_prefsBox.get(_platformKey) as String?);

  @override
  String? get targetUrl => _prefsBox.get(_urlKey) as String?;

  @override
  String? get selectedBrowser =>
      _prefsBox.get(_browserKey) as String? ?? 'chromium';

  @override
  Future<void> setPlatform(AutomationPlatformType platform) async {
    await _prefsBox.put(_platformKey, platform.name);
  }

  @override
  Future<void> setTargetUrl(String? url) async {
    if (url == null) {
      await _prefsBox.delete(_urlKey);
    } else {
      await _prefsBox.put(_urlKey, url);
    }
  }

  @override
  Future<void> setBrowser(String browser) async {
    await _prefsBox.put(_browserKey, browser);
  }

  @override
  Future<bool> isPlatformAvailable(AutomationPlatformType platform) =>
      _orchestrator.isAvailable(platform);

  @override
  Future<bool> isAccessibilityEnabled() =>
      _orchestrator.isAccessibilityEnabled();

  @override
  Future<bool> isOverlayGranted() => _orchestrator.isOverlayGranted();

  @override
  Future<void> openAccessibilitySettings() =>
      _orchestrator.openAccessibilitySettings();

  @override
  Future<void> openOverlaySettings() => _orchestrator.openOverlaySettings();

  @override
  Future<AutomationSessionConfig> buildSessionConfig(
    Map<String, String> fieldData, {
    List<String> uploadPaths = const [],
  }) async {
    return AutomationSessionConfig(
      platform: selectedPlatform,
      fieldData: fieldData,
      targetUrl: targetUrl,
      browser: _parseBrowser(selectedBrowser),
      uploadPaths: uploadPaths,
      maxScrollRetries: AppConstants.maxScrollRetries,
      scrollDelayMs: AppConstants.scrollDelayMs,
      retryDelayMs: AppConstants.fieldDetectionRetryMs,
      ocrThreshold: AppConstants.ocrConfidenceThreshold,
      useOcrAssist: selectedPlatform == AutomationPlatformType.hybridOcr,
    );
  }

  @override
  Future<void> startAutomation({
    required Map<String, String> fieldData,
    List<String> uploadPaths = const [],
  }) async {
    await _logs.addQuick(
      tag: 'Automation',
      level: LogLevel.info,
      message:
          'Starting ${selectedPlatform.label} with ${fieldData.length} fields',
    );
    final config = await buildSessionConfig(
      fieldData,
      uploadPaths: uploadPaths,
    );
    await _orchestrator.start(config);
  }

  @override
  Future<void> stopAutomation() async {
    await _orchestrator.stop();
    await _logs.addQuick(
      tag: 'Automation',
      level: LogLevel.warning,
      message: 'Automation stopped',
    );
  }

  @override
  Future<void> pauseAutomation() => _orchestrator.pause();

  @override
  Future<void> resumeAutomation() => _orchestrator.resume();

  BrowserType _parseBrowser(String? raw) {
    switch (raw) {
      case 'chrome':
        return BrowserType.chrome;
      case 'msedge':
        return BrowserType.msedge;
      case 'firefox':
        return BrowserType.firefox;
      default:
        return BrowserType.chromium;
    }
  }
}
