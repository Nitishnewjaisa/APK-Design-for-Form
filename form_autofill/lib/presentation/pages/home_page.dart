import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../automation/shared/automation_platform_type.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/automation_status.dart';
import '../providers/app_providers.dart';
import '../widgets/browser_automation_panel.dart';
import '../widgets/platform_selector.dart';
import 'debug_panel_page.dart';
import 'profile_editor_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppConstants.appName),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: state.refreshPermissions,
                tooltip: 'Refresh permissions',
              ),
            ],
          ),
          body: IndexedStack(
            index: _tabIndex,
            children: [
              _DashboardTab(state: state),
              ProfileEditorPage(
                profiles: state.profileList,
                activeProfile: state.activeProfile,
                onSave: state.saveProfile,
                onDelete: state.deleteProfile,
                onSetActive: state.setActiveProfile,
              ),
              SettingsPage(
                accessibilityEnabled: state.accessibilityEnabled,
                overlayGranted: state.overlayGranted,
                onOpenAccessibility: state.openAccessibilitySettings,
                onOpenOverlay: state.openOverlaySettings,
                onRefresh: state.refreshPermissions,
              ),
              DebugPanelPage(
                logs: state.logEntries,
                status: state.automationStatus,
                onClear: state.clearLogs,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profiles',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
              NavigationDestination(
                icon: Icon(Icons.bug_report_outlined),
                selectedIcon: Icon(Icons.bug_report),
                label: 'Debug',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final AppState state;

  const _DashboardTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.automationStatus;
    final isRunning = status.state != AutomationState.idle &&
        status.state != AutomationState.completed &&
        status.state != AutomationState.error &&
        status.state != AutomationState.stopped;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(status: status),
        const SizedBox(height: 16),
        PlatformSelector(
          selected: state.selectedPlatform,
          availability: state.platformAvailability,
          onChanged: state.setPlatform,
        ),
        const SizedBox(height: 12),
        if (state.selectedPlatform == AutomationPlatformType.browser ||
            state.selectedPlatform == AutomationPlatformType.hybridOcr)
          BrowserAutomationPanel(
            targetUrl: state.targetUrl,
            selectedBrowser: state.selectedBrowser,
            onUrlChanged: state.setTargetUrl,
            onBrowserChanged: state.setBrowser,
          ),
        if (state.selectedPlatform == AutomationPlatformType.android ||
            state.selectedPlatform == AutomationPlatformType.hybridOcr) ...[
          const SizedBox(height: 12),
          _PermissionCard(
            accessibility: state.accessibilityEnabled,
            overlay: state.overlayGranted,
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.activeProfile?.name ?? 'No profile selected',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (state.activeProfile != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${state.activeProfile!.fields.length} fields configured',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: state.canStartAutomation && !isRunning
              ? () => _confirmStart(context, state)
              : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Auto-Fill'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 12),
        if (isRunning)
          OutlinedButton.icon(
            onPressed: state.stopAutomation,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'How to use',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(_howToUse(state.selectedPlatform)),
      ],
    );
  }

  String _howToUse(AutomationPlatformType platform) {
    switch (platform) {
      case AutomationPlatformType.browser:
      case AutomationPlatformType.web:
        return '1. Start Playwright: npm start in automation/playwright\n'
            '2. Enter form URL above\n'
            '3. Create a profile with your data\n'
            '4. Tap Start — browser opens and fills automatically';
      case AutomationPlatformType.hybridOcr:
        return '1. Browser: start Playwright sidecar + enter URL\n'
            '2. Android: enable Accessibility in Settings\n'
            '3. Uses OCR-assisted matching across platforms';
      case AutomationPlatformType.windows:
        return '1. Windows desktop automation is prepared (Win32/UIA)\n'
            '2. Use Browser Automation for forms today';
      case AutomationPlatformType.android:
        return '1. Enable Accessibility & Overlay in Settings\n'
            '2. Create a profile with your form data\n'
            '3. Open the target form app\n'
            '4. Tap Start Auto-Fill';
    }
  }

  Future<void> _confirmStart(BuildContext context, AppState state) async {
    final msg = state.selectedPlatform == AutomationPlatformType.browser
        ? 'Playwright will open the browser and fill the form at:\n${state.targetUrl ?? ""}'
        : 'Automation will start on the active target.';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Auto-Fill?'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await state.startAutomation();
    }
  }
}

class _StatusCard extends StatelessWidget {
  final AutomationStatus status;

  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automation Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_stateLabel(status.state),
                style: Theme.of(context).textTheme.headlineSmall),
            if (status.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(status.message),
            ],
            if (status.fieldsTotal > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: status.fieldsTotal > 0
                    ? status.fieldsFilled / status.fieldsTotal
                    : 0,
              ),
              const SizedBox(height: 4),
              Text(
                '${status.fieldsFilled}/${status.fieldsTotal} fields · ${status.scrollCount} scrolls',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stateLabel(AutomationState s) {
    switch (s) {
      case AutomationState.idle:
        return 'Ready';
      case AutomationState.scanning:
        return 'Scanning fields…';
      case AutomationState.filling:
        return 'Filling fields…';
      case AutomationState.scrolling:
        return 'Scrolling form…';
      case AutomationState.waitingDropdown:
        return 'Selecting dropdown…';
      case AutomationState.completed:
        return 'Completed';
      case AutomationState.error:
        return 'Error';
      case AutomationState.stopped:
        return 'Stopped';
    }
  }
}

class _PermissionCard extends StatelessWidget {
  final bool accessibility;
  final bool overlay;

  const _PermissionCard({
    required this.accessibility,
    required this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PermRow(
              label: 'Accessibility Service',
              ok: accessibility,
            ),
            const Divider(),
            _PermRow(label: 'Overlay Permission', ok: overlay),
          ],
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final String label;
  final bool ok;

  const _PermRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          color: ok ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(ok ? 'Granted' : 'Required',
            style: TextStyle(
              color: ok ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}
