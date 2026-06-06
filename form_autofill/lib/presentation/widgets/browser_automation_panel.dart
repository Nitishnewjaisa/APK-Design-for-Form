import 'package:flutter/material.dart';

class BrowserAutomationPanel extends StatefulWidget {
  final String? targetUrl;
  final String selectedBrowser;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onBrowserChanged;

  const BrowserAutomationPanel({
    super.key,
    required this.targetUrl,
    required this.selectedBrowser,
    required this.onUrlChanged,
    required this.onBrowserChanged,
  });

  @override
  State<BrowserAutomationPanel> createState() => _BrowserAutomationPanelState();
}

class _BrowserAutomationPanelState extends State<BrowserAutomationPanel> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.targetUrl ?? '');
  }

  @override
  void didUpdateWidget(BrowserAutomationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetUrl != oldWidget.targetUrl &&
        widget.targetUrl != _urlController.text) {
      _urlController.text = widget.targetUrl ?? '';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browser Automation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Form URL',
                hintText: 'https://example.com/apply',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onChanged: widget.onUrlChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.selectedBrowser,
              decoration: const InputDecoration(
                labelText: 'Browser Engine',
                prefixIcon: Icon(Icons.web),
              ),
              items: const [
                DropdownMenuItem(value: 'chromium', child: Text('Chromium')),
                DropdownMenuItem(
                    value: 'chrome', child: Text('Google Chrome')),
                DropdownMenuItem(
                    value: 'msedge', child: Text('Microsoft Edge')),
                DropdownMenuItem(value: 'firefox', child: Text('Firefox')),
              ],
              onChanged: (v) {
                if (v != null) widget.onBrowserChanged(v);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Requires Playwright sidecar: npm start in automation/playwright',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
