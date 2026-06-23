import 'package:flutter/foundation.dart';

/// Kind of trailing control on an actionable toast.
enum TilawaFeedbackActionKind {
  /// Primary affordance — undo, retry, update.
  primary,

  /// Secondary dismiss — closes without running a domain action.
  dismiss,
}

/// A tappable trailing control on [TilawaFeedback.showActionable] toasts.
@immutable
class TilawaFeedbackAction {
  /// Creates an actionable toast control.
  const TilawaFeedbackAction({
    required this.label,
    required this.onPressed,
    this.kind = TilawaFeedbackActionKind.primary,
  });

  /// Caller-localized action label.
  final String label;

  /// Invoked when the user taps the action.
  final VoidCallback onPressed;

  /// Visual and semantic role of the control.
  final TilawaFeedbackActionKind kind;
}
