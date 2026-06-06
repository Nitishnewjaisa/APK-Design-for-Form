import '../../../domain/entities/automation_status.dart';
import 'automation_platform_type.dart';
import 'automation_session_config.dart';

/// Platform adapter contract — Android, Playwright, Windows, Hybrid.
abstract class AutomationAdapter {
  AutomationPlatformType get platformType;

  Stream<AutomationStatus> get statusStream;

  Future<bool> isAvailable();

  Future<void> start(AutomationSessionConfig config);

  Future<void> stop();

  Future<void> pause();

  Future<void> resume();

  /// Platform-specific permission/setup hooks.
  Future<void> prepareEnvironment();
}
