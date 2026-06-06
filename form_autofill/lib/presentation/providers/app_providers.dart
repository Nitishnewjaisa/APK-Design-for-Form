import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../automation/shared/automation_orchestrator.dart';
import '../../automation/shared/automation_platform_type.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/log_local_datasource.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/repositories/automation_repository_impl.dart';
import '../../data/repositories/log_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/automation_status.dart';
import '../../domain/entities/debug_log_entry.dart';
import '../../domain/entities/form_profile.dart';
import '../../domain/repositories/automation_repository.dart';
import '../../domain/repositories/log_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class AppState extends ChangeNotifier {
  final ProfileRepository profiles;
  final AutomationRepository automation;
  final LogRepository logs;

  List<FormProfile> _profileList = [];
  FormProfile? _activeProfile;
  AutomationStatus _automationStatus =
      const AutomationStatus(state: AutomationState.idle);
  List<DebugLogEntry> _logEntries = [];
  bool _accessibilityEnabled = false;
  bool _overlayGranted = false;
  bool _loading = true;
  Map<AutomationPlatformType, bool> _platformAvailability = {};

  AppState({
    required this.profiles,
    required this.automation,
    required this.logs,
  });

  List<FormProfile> get profileList => _profileList;
  FormProfile? get activeProfile => _activeProfile;
  AutomationStatus get automationStatus => _automationStatus;
  List<DebugLogEntry> get logEntries => _logEntries;
  bool get accessibilityEnabled => _accessibilityEnabled;
  bool get overlayGranted => _overlayGranted;
  bool get loading => _loading;

  AutomationPlatformType get selectedPlatform => automation.selectedPlatform;
  String? get targetUrl => automation.targetUrl;
  String get selectedBrowser => automation.selectedBrowser ?? 'chromium';
  Map<AutomationPlatformType, bool> get platformAvailability =>
      _platformAvailability;

  bool get canStartAutomation {
    if (_activeProfile == null) return false;
    switch (selectedPlatform) {
      case AutomationPlatformType.android:
      case AutomationPlatformType.hybridOcr:
        return _accessibilityEnabled;
      case AutomationPlatformType.browser:
      case AutomationPlatformType.web:
        return (targetUrl?.isNotEmpty ?? false) &&
            (_platformAvailability[AutomationPlatformType.browser] ?? false);
      case AutomationPlatformType.windows:
        return _platformAvailability[AutomationPlatformType.windows] ?? false;
    }
  }

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    await refreshPermissions();
    await _checkPlatformAvailability();
    await loadProfiles();
    automation.statusStream.listen((status) {
      _automationStatus = status;
      notifyListeners();
    });
    logs.watchLogs().listen((entries) {
      _logEntries = entries;
      notifyListeners();
    });
    _loading = false;
    notifyListeners();
  }

  Future<void> _checkPlatformAvailability() async {
    final map = <AutomationPlatformType, bool>{};
    for (final p in AutomationPlatformType.values) {
      if (p == AutomationPlatformType.web) continue;
      map[p] = await automation.isPlatformAvailable(p);
    }
    _platformAvailability = map;
  }

  Future<void> refreshPermissions() async {
    _accessibilityEnabled = await automation.isAccessibilityEnabled();
    _overlayGranted = await automation.isOverlayGranted();
    await _checkPlatformAvailability();
    notifyListeners();
  }

  Future<void> setPlatform(AutomationPlatformType platform) async {
    await automation.setPlatform(platform);
    notifyListeners();
  }

  Future<void> setTargetUrl(String url) async {
    await automation.setTargetUrl(url);
    notifyListeners();
  }

  Future<void> setBrowser(String browser) async {
    await automation.setBrowser(browser);
    notifyListeners();
  }

  Future<void> loadProfiles() async {
    _profileList = await profiles.getAllProfiles();
    _activeProfile = await profiles.getActiveProfile();
    notifyListeners();
  }

  Future<void> saveProfile(FormProfile profile) async {
    await profiles.saveProfile(profile);
    await loadProfiles();
  }

  Future<void> deleteProfile(String id) async {
    await profiles.deleteProfile(id);
    await loadProfiles();
  }

  Future<void> setActiveProfile(String id) async {
    await profiles.setActiveProfile(id);
    await loadProfiles();
  }

  Future<void> startAutomation({List<String> uploadPaths = const []}) async {
    final fields = await profiles.getActiveFieldMap();
    if (fields.isEmpty) return;
    await automation.startAutomation(
      fieldData: fields,
      uploadPaths: uploadPaths,
    );
  }

  Future<void> stopAutomation() => automation.stopAutomation();

  Future<void> openAccessibilitySettings() =>
      automation.openAccessibilitySettings();

  Future<void> openOverlaySettings() => automation.openOverlaySettings();

  Future<void> clearLogs() => logs.clearLogs();
}

List<SingleChildWidget> buildProviders() {
  final profilesBox = Hive.box(AppConstants.hiveProfilesBox);
  final logsBox = Hive.box(AppConstants.hiveLogsBox);
  final prefsBox = Hive.box(AppConstants.hivePrefsBox);

  final profileRepo = ProfileRepositoryImpl(
    ProfileLocalDatasource(profilesBox),
  );
  final logDatasource = LogLocalDatasource(logsBox);
  final logRepo = LogRepositoryImpl(logDatasource);
  final orchestrator = AutomationOrchestrator();
  final automationRepo = AutomationRepositoryImpl(
    orchestrator,
    logDatasource,
    prefsBox,
  );

  return [
    Provider<ProfileRepository>.value(value: profileRepo),
    Provider<AutomationRepository>.value(value: automationRepo),
    Provider<LogRepository>.value(value: logRepo),
    Provider<AutomationOrchestrator>.value(value: orchestrator),
    ChangeNotifierProvider(
      create: (_) => AppState(
        profiles: profileRepo,
        automation: automationRepo,
        logs: logRepo,
      )..initialize(),
    ),
  ];
}
