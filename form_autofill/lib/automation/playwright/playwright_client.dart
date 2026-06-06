import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/entities/automation_status.dart';
import '../shared/automation_session_config.dart';

/// HTTP client for the local Playwright automation sidecar.
class PlaywrightClient {
  final String baseUrl;
  final http.Client _http;

  PlaywrightClient({
    this.baseUrl = 'http://127.0.0.1:3939',
    http.Client? client,
  }) : _http = client ?? http.Client();

  Future<bool> healthCheck() async {
    try {
      final res = await _http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> start(AutomationSessionConfig config) async {
    final res = await _http.post(
      Uri.parse('$baseUrl/automation/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_buildPayload(config)),
    );
    if (res.statusCode >= 400) {
      throw Exception('Playwright start failed: ${res.body}');
    }
  }

  Future<void> stop() async {
    await _http.post(Uri.parse('$baseUrl/automation/stop'));
  }

  Future<void> pause() async {
    await _http.post(Uri.parse('$baseUrl/automation/pause'));
  }

  Future<void> resume() async {
    await _http.post(Uri.parse('$baseUrl/automation/resume'));
  }

  Stream<AutomationStatus> statusStream() async* {
    while (true) {
      try {
        final res = await _http.get(Uri.parse('$baseUrl/automation/status'));
        // Debug fields returned from Playwright (optional) are handled below.
        if (res.statusCode == 200) {
          yield _mapStatus(jsonDecode(res.body) as Map<String, dynamic>);
        }
      } catch (_) {
        yield const AutomationStatus(
          state: AutomationState.error,
          message: 'Playwright service unreachable',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Map<String, dynamic> _buildPayload(AutomationSessionConfig config) => {
        'url': config.targetUrl,
        'fields': config.fieldData,
        'browser': config.browser.name,
        'uploadPaths': config.uploadPaths,
        'maxScrollRetries': config.maxScrollRetries,
        'scrollDelayMs': config.scrollDelayMs,
        'retryDelayMs': config.retryDelayMs,
        'ocrThreshold': config.ocrThreshold,
        'useOcrAssist': config.useOcrAssist,
      };

  AutomationStatus _mapStatus(Map<String, dynamic> map) => AutomationStatus(
        state: _parseState(map['state'] as String?),
        message: map['message'] as String? ?? '',
        fieldsFilled: map['fieldsFilled'] as int? ?? 0,
        fieldsTotal: map['fieldsTotal'] as int? ?? 0,
        scrollCount: map['scrollCount'] as int? ?? 0,
      );


  AutomationState _parseState(String? raw) {
    switch (raw) {
      case 'scanning':
        return AutomationState.scanning;
      case 'filling':
        return AutomationState.filling;
      case 'scrolling':
        return AutomationState.scrolling;
      case 'waitingDropdown':
        return AutomationState.waitingDropdown;
      case 'completed':
        return AutomationState.completed;
      case 'error':
        return AutomationState.error;
      case 'stopped':
        return AutomationState.stopped;
      default:
        return AutomationState.idle;
    }
  }

  void close() => _http.close();
}
