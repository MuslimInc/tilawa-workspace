import 'package:flutter/material.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'design_tokens.dart';
import 'tilawa_feedback_style.dart';

/// Transient bottom feedback surfaced by [TilawaFeedbackHost].
///
/// Callers use [TilawaFeedback.showToast]; do not insert this widget directly.
class TilawaToast extends StatelessWidget {
  /// Creates a toast for the given [variant] and localized [message].
  const TilawaToast({
    super.key,
    required this.variant,
    required this.message,
  });

  /// Semantic intent.
  final TilawaFeedbackVariant variant;

  /// Caller-localized copy.
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TilawaFeedbackStyle style = TilawaFeedbackStyle.forVariant(
      context,
      variant,
    );
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.chrome,
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(
                alpha: tokens.opacityShadowStrong,
              ),
              blurRadius: tokens.shadowOffsetMedium.dy * 4,
              offset: tokens.shadowOffsetMedium,
            ),
          ],
        ),
        child: TilawaFeedbackStrip(
          icon: style.icon,
          message: message,
          backgroundColor: style.backgroundColor,
          foregroundColor: style.foregroundColor,
          variant: variant,
        ),
      ),
    );
  }
}
