// Backward-compatible export — delegates to Android adapter.
export '../../automation/android/android_automation_adapter.dart'
    show AndroidAutomationAdapter;

@Deprecated('Use AndroidAutomationAdapter or AutomationOrchestrator')
typedef AutomationPlatform = AndroidAutomationAdapter;
