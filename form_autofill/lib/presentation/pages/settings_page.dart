import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final bool accessibilityEnabled;
  final bool overlayGranted;
  final Future<void> Function() onOpenAccessibility;
  final Future<void> Function() onOpenOverlay;
  final Future<void> Function() onRefresh;

  const SettingsPage({
    super.key,
    required this.accessibilityEnabled,
    required this.overlayGranted,
    required this.onOpenAccessibility,
    required this.onOpenOverlay,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Permissions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.accessibility_new,
          title: 'Accessibility Service',
          subtitle: accessibilityEnabled
              ? 'Enabled — Form AutoFill Pro is active'
              : 'Required for field detection and auto-fill',
          trailing: accessibilityEnabled
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onOpenAccessibility,
        ),
        _SettingsTile(
          icon: Icons.layers,
          title: 'Display Over Other Apps',
          subtitle: overlayGranted
              ? 'Overlay permission granted'
              : 'Shows automation status overlay',
          trailing: overlayGranted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onOpenOverlay,
        ),
        const SizedBox(height: 24),
        Text('Automation', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Steps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const _Step(number: 1, text: 'Enable Accessibility Service'),
                const _Step(
                  number: 2,
                  text: 'Grant overlay permission (optional)',
                ),
                const _Step(number: 3, text: 'Create a data profile'),
                const _Step(
                  number: 4,
                  text: 'Open target form app and tap Start',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Permission Status'),
        ),
        const SizedBox(height: 24),
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Hybrid automation:\n'
          '• Android — Accessibility Service + ML Kit OCR\n'
          '• Browser — Playwright sidecar (Chrome/Edge)\n'
          '• Desktop OCR — Tesseract (install separately)\n'
          '• Windows native — prepared for future Win32/UIA',
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$number', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
