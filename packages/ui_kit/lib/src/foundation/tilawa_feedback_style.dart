import 'package:flutter/material.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'color_scheme_ext.dart';

/// Resolved colours and icon for a [TilawaFeedbackVariant].
@immutable
class TilawaFeedbackStyle {
  /// Creates a feedback style bundle.
  const TilawaFeedbackStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  /// Strip / toast surface fill.
  final Color backgroundColor;

  /// Icon and message colour.
  final Color foregroundColor;

  /// Leading status icon.
  final IconData icon;

  /// Maps [variant] to theme-aware strip/toast styling.
  static TilawaFeedbackStyle forVariant(
    BuildContext context,
    TilawaFeedbackVariant variant,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (variant) {
      TilawaFeedbackVariant.success => TilawaFeedbackStyle(
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.success,
        icon: Icons.check_circle_outline,
      ),
      TilawaFeedbackVariant.error => TilawaFeedbackStyle(
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.error,
        icon: Icons.error_outline,
      ),
      TilawaFeedbackVariant.warning => TilawaFeedbackStyle(
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.warning,
        icon: Icons.warning_amber_outlined,
      ),
      TilawaFeedbackVariant.info => TilawaFeedbackStyle(
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.onSurfaceVariant,
        icon: Icons.info_outline,
      ),
    };
  }
}
