import 'package:flutter/material.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'tilawa_feedback_action.dart';
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
    String? dedupeKey,
  }) {
    TilawaFeedbackScope.of(context).showToast(
      context: context,
      message: message,
      variant: variant,
      duration: duration,
      dedupeKey: dedupeKey,
    );
  }

  /// Shows a toast with one or more trailing actions.
  ///
  /// Pass [duration] as `null` to keep the toast until the user acts.
  static void showActionable(
    BuildContext context, {
    required String message,
    required TilawaFeedbackVariant variant,
    Duration? duration = kTilawaUndoToastDuration,
    required List<TilawaFeedbackAction> actions,
    String? dedupeKey,
  }) {
    TilawaFeedbackScope.of(context).showActionable(
      context: context,
      message: message,
      variant: variant,
      duration: duration,
      actions: actions,
      dedupeKey: dedupeKey,
    );
  }

  /// Dismisses the active toast when [dedupeKey] matches, or any active toast
  /// when [dedupeKey] is null.
  static void dismiss(BuildContext context, {String? dedupeKey}) {
    TilawaFeedbackScope.of(context).dismiss(dedupeKey: dedupeKey);
  }
}
