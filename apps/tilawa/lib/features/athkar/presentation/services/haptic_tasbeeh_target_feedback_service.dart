import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vibration/vibration.dart';

import '../../domain/services/tasbeeh_target_feedback_service.dart';

@LazySingleton(as: TasbeehTargetFeedbackService)
class HapticTasbeehTargetFeedbackService
    implements TasbeehTargetFeedbackService {
  @override
  Future<void> onTargetReached() async {
    try {
      final bool hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        final bool hasAmplitude = await Vibration.hasAmplitudeControl();
        await Vibration.vibrate(
          duration: 220,
          amplitude: hasAmplitude ? 180 : -1,
        );
        return;
      }
    } catch (_) {
      // Fall back to Flutter haptics when direct vibrator API is unavailable.
    }

    try {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
    } catch (_) {
      // Intentionally swallow platform haptic failures.
    }
  }
}
