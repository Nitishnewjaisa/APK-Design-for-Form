import '../../automation/shared/automation_platform_type.dart';
import '../../automation/shared/automation_session_config.dart';
import '../entities/automation_status.dart';

abstract class AutomationRepository {
  Stream<AutomationStatus> get statusStream;

  AutomationPlatformType get selectedPlatform;
  String? get targetUrl;
  String? get selectedBrowser;

  Future<void> setPlatform(AutomationPlatformType platform);
  Future<void> setTargetUrl(String? url);
  Future<void> setBrowser(String browser);

  Future<bool> isPlatformAvailable(AutomationPlatformType platform);

  // Android-specific (preserved)
  Future<bool> isAccessibilityEnabled();
  Future<bool> isOverlayGranted();
  Future<void> openAccessibilitySettings();
  Future<void> openOverlaySettings();

  Future<void> startAutomation({
    required Map<String, String> fieldData,
    List<String> uploadPaths,
  });

  Future<void> stopAutomation();
  Future<void> pauseAutomation();
  Future<void> resumeAutomation();

  Future<AutomationSessionConfig> buildSessionConfig(
    Map<String, String> fieldData, {
    List<String> uploadPaths,
  });
}
