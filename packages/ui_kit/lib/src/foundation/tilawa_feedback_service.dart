import 'package:flutter/material.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'tilawa_feedback.dart';
import 'tilawa_feedback_action.dart';
import 'tilawa_feedback_host.dart';

/// Feedback helpers for layers that only hold a [GlobalKey] navigator reference.
abstract final class TilawaFeedbackService {
  /// Shows a toast when [navigatorKey] resolves to a mounted context.
  static void showToast(
    GlobalKey<NavigatorState> navigatorKey, {
    required String message,
    required TilawaFeedbackVariant variant,
    Duration duration = kTilawaToastDuration,
    String? dedupeKey,
  }) {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    TilawaFeedback.showToast(
      context,
      message: message,
      variant: variant,
      duration: duration,
      dedupeKey: dedupeKey,
    );
  }

  /// Shows an actionable toast when [navigatorKey] resolves to a mounted context.
  static void showActionable(
    GlobalKey<NavigatorState> navigatorKey, {
    required String message,
    required TilawaFeedbackVariant variant,
    Duration? duration = kTilawaUndoToastDuration,
    required List<TilawaFeedbackAction> actions,
    String? dedupeKey,
  }) {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    TilawaFeedback.showActionable(
      context,
      message: message,
      variant: variant,
      duration: duration,
      actions: actions,
      dedupeKey: dedupeKey,
    );
  }
}
