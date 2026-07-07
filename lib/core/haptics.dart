import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'game_settings.dart';

/// Stronger, amplitude-controlled haptics using the raw vibration motor
/// where available (most Android devices), falling back to the built-in
/// [HapticFeedback] constants (which are often too subtle to feel) when
/// the platform doesn't support custom vibration.
class Haptics {
  Haptics._();

  static Future<bool>? _amplitudeSupport;
  static Future<bool>? _hasVibrator;

  static Future<bool> get _supportsAmplitude {
    return _amplitudeSupport ??= Vibration.hasAmplitudeControl().catchError(
      (_) => false,
    );
  }

  static Future<bool> get _deviceHasVibrator {
    return _hasVibrator ??= Vibration.hasVibrator().catchError((_) => false);
  }

  /// Picking up an element to drag.
  static void grab() =>
      _fire(duration: 35, amplitude: 255, fallback: HapticFeedback.heavyImpact);

  /// Dropping/releasing an element.
  static void drop() => _fire(
    duration: 20,
    amplitude: 180,
    fallback: HapticFeedback.mediumImpact,
  );

  /// Two elements successfully combining.
  static void combine() =>
      _fire(duration: 45, amplitude: 255, fallback: HapticFeedback.heavyImpact);

  /// A combination failed / an error occurred.
  static void error() =>
      _fire(duration: 60, amplitude: 220, fallback: HapticFeedback.vibrate);

  static Future<void> _fire({
    required int duration,
    required int amplitude,
    required Future<void> Function() fallback,
  }) async {
    if (!GameSettings.hapticsEnabled) return;
    try {
      if (await _deviceHasVibrator) {
        final hasAmplitude = await _supportsAmplitude;
        await Vibration.vibrate(
          duration: duration,
          amplitude: hasAmplitude ? amplitude : -1,
        );
        return;
      }
    } catch (_) {
      // Fall through to platform haptic constants below.
    }
    await fallback();
  }
}
