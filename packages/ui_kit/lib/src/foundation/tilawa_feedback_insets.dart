import 'package:flutter/material.dart';

/// Optional bottom obstruction reported by screens with sticky footers.
///
/// Wrap a subtree (e.g. a form with [TilawaBottomActionArea]) so transient
/// toasts float above pinned CTAs instead of covering them.
class TilawaFeedbackInsets extends InheritedWidget {
  /// Creates feedback inset overrides for descendant [TilawaFeedback.showToast]
  /// calls.
  const TilawaFeedbackInsets({
    super.key,
    required this.bottomObstruction,
    required super.child,
  });

  /// Extra bottom clearance in logical pixels (sticky footer band height).
  final double bottomObstruction;

  /// Returns [bottomObstruction] from the nearest ancestor, or zero.
  static double maybeBottomObstruction(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<TilawaFeedbackInsets>()
            ?.bottomObstruction ??
        0;
  }

  @override
  bool updateShouldNotify(TilawaFeedbackInsets oldWidget) =>
      bottomObstruction != oldWidget.bottomObstruction;
}
