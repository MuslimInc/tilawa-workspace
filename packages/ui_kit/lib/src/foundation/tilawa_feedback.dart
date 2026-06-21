import 'package:flutter/material.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'tilawa_feedback_host.dart';

/// App-wide transient and persistent feedback entry points.
abstract final class TilawaFeedback {
  /// Shows a calm, auto-dismissing toast above bottom chrome.
  ///
  /// [message] must already be localized by the caller.
  static void showToast(
    BuildContext context, {
    required String message,
    required TilawaFeedbackVariant variant,
    Duration duration = kTilawaToastDuration,
  }) {
    TilawaFeedbackScope.of(context).showToast(
      context: context,
      message: message,
      variant: variant,
      duration: duration,
    );
  }
}
