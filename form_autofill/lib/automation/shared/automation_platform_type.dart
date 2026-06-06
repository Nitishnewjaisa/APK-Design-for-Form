/// Supported automation runtimes across the hybrid system.
enum AutomationPlatformType {
  android('Android Automation', 'Native apps via Accessibility Service'),
  browser('Browser Automation', 'Chrome/Edge forms via Playwright'),
  hybridOcr('Hybrid OCR Automation', 'OCR-assisted fill across platforms'),
  windows('Windows Desktop', 'Win32/UI automation (prepared)'),
  web('Web Form Automation', 'Browser automation alias');

  const AutomationPlatformType(this.label, this.description);

  final String label;
  final String description;

  /// Resolves browser/web to Playwright-backed runtime.
  AutomationPlatformType get resolvedRuntime {
    if (this == AutomationPlatformType.web) {
      return AutomationPlatformType.browser;
    }
    return this;
  }

  static AutomationPlatformType fromId(String? id) {
    return AutomationPlatformType.values.firstWhere(
      (p) => p.name == id,
      orElse: () => AutomationPlatformType.android,
    );
  }
}
