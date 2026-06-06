import 'automation_platform_type.dart';

/// Platform-independent session configuration passed to adapters.
class AutomationSessionConfig {
  final AutomationPlatformType platform;
  final Map<String, String> fieldData;
  final String? targetUrl;
  final BrowserType browser;
  final List<String> uploadPaths;
  final int maxScrollRetries;
  final int scrollDelayMs;
  final int retryDelayMs;
  final int ocrThreshold;
  final bool useOcrAssist;

  const AutomationSessionConfig({
    required this.platform,
    required this.fieldData,
    this.targetUrl,
    this.browser = BrowserType.chromium,
    this.uploadPaths = const [],
    this.maxScrollRetries = 8,
    this.scrollDelayMs = 600,
    this.retryDelayMs = 400,
    this.ocrThreshold = 65,
    this.useOcrAssist = false,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform.name,
        'fields': fieldData,
        'targetUrl': targetUrl,
        'browser': browser.name,
        'uploadPaths': uploadPaths,
        'maxScrollRetries': maxScrollRetries,
        'scrollDelayMs': scrollDelayMs,
        'retryDelayMs': retryDelayMs,
        'ocrThreshold': ocrThreshold,
        'useOcrAssist': useOcrAssist,
      };
}

enum BrowserType { chromium, chrome, msedge, firefox }
