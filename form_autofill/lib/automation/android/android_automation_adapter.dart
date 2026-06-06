import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/automation_status.dart';
import '../shared/automation_adapter.dart';
import '../shared/automation_platform_type.dart';
import '../shared/automation_session_config.dart';

/// Wraps existing Android Accessibility Service bridge (preserved).
class AndroidAutomationAdapter implements AutomationAdapter {
  static const _channel = MethodChannel(AppConstants.channelAutomation);
  static const _eventChannel =
      EventChannel('${AppConstants.channelAutomation}/events');

  Stream<AutomationStatus>? _statusStream;

  @override
  AutomationPlatformType get platformType => AutomationPlatformType.android;

  @override
  Stream<AutomationStatus> get statusStream {
    _statusStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(_mapStatus)
        .handleError(
          (_) => const AutomationStatus(
            state: AutomationState.error,
            message: 'Android event stream error',
          ),
        );
    return _statusStream!;
  }

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  @override
  Future<void> prepareEnvironment() async {}

  @override
  Future<void> start(AutomationSessionConfig config) async {
    await _channel.invokeMethod('startAutomation', {
      'fields': config.fieldData,
      'maxScrollRetries': config.maxScrollRetries,
      'scrollDelayMs': config.scrollDelayMs,
      'retryDelayMs': config.retryDelayMs,
      'ocrThreshold': config.ocrThreshold,
      'useOcrAssist': config.useOcrAssist,
    });
  }

  @override
  Future<void> stop() => _channel.invokeMethod('stopAutomation');

  @override
  Future<void> pause() => _channel.invokeMethod('pauseAutomation');

  @override
  Future<void> resume() => _channel.invokeMethod('resumeAutomation');

  Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isOverlayGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayGranted');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() =>
      _channel.invokeMethod('openAccessibilitySettings');

  Future<void> openOverlaySettings() =>
      _channel.invokeMethod('openOverlaySettings');

  AutomationStatus _mapStatus(dynamic event) {
    if (event is! Map) {
      return const AutomationStatus(state: AutomationState.idle);
    }
    final map = Map<String, dynamic>.from(event);
    return AutomationStatus(
      state: _parseState(map['state'] as String?),
      message: map['message'] as String? ?? '',
      fieldsFilled: map['fieldsFilled'] as int? ?? 0,
      fieldsTotal: map['fieldsTotal'] as int? ?? 0,
      scrollCount: map['scrollCount'] as int? ?? 0,
    );
  }

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
}
