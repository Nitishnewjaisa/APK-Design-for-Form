import 'package:flutter/material.dart';

import '../../automation/shared/automation_platform_type.dart';

class PlatformSelector extends StatelessWidget {
  final AutomationPlatformType selected;
  final ValueChanged<AutomationPlatformType> onChanged;
  final Map<AutomationPlatformType, bool>? availability;

  const PlatformSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.availability,
  });

  @override
  Widget build(BuildContext context) {
    final platforms = [
      AutomationPlatformType.android,
      AutomationPlatformType.browser,
      AutomationPlatformType.hybridOcr,
      AutomationPlatformType.windows,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automation Platform',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...platforms.map((p) {
              final available = availability?[p] ?? true;
              return RadioListTile<AutomationPlatformType>(
                value: p,
                groupValue: selected,
                onChanged: available ? onChanged : null,
                title: Text(p.label),
                subtitle: Text(
                  p.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                secondary: Icon(_iconFor(p), color: available ? null : Colors.grey),
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AutomationPlatformType p) {
    switch (p) {
      case AutomationPlatformType.android:
        return Icons.android;
      case AutomationPlatformType.browser:
      case AutomationPlatformType.web:
        return Icons.language;
      case AutomationPlatformType.hybridOcr:
        return Icons.document_scanner_outlined;
      case AutomationPlatformType.windows:
        return Icons.desktop_windows;
    }
  }
}
