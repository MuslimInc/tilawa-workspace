import 'package:flutter/material.dart';

import '../atoms/tilawa_loading_indicator.dart';
import '../foundation/component_tokens.dart';

/// Semantic intent for [TilawaFeedbackStrip] (affects a11y label + border).
enum TilawaFeedbackVariant {
  // fix: Feedback & states — structured info / warn / error presentation
  info,
  warning,
  error,
}

class TilawaFeedbackStrip extends StatelessWidget {
  const TilawaFeedbackStrip({
    super.key,
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    this.showSpinner = false,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.variant,
  });

  final IconData icon;
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool showSpinner;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  /// Optional intent for semantics and default border treatment.
  final TilawaFeedbackVariant? variant;

  static Color? _accentForVariant(
    BuildContext context,
    TilawaFeedbackVariant? v,
  ) {
    if (v == null) return null;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return switch (v) {
      TilawaFeedbackVariant.info => cs.outline.withValues(alpha: 0.35),
      TilawaFeedbackVariant.warning => cs.error.withValues(alpha: 0.45),
      TilawaFeedbackVariant.error => cs.error.withValues(alpha: 0.72),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.feedbackStrip;
    final double radius = borderRadius ?? componentTokens.borderRadius;
    final Color? accentColor =
        borderColor ?? _accentForVariant(context, variant);

    final BoxDecoration decoration;
    if (accentColor != null) {
      decoration = BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accentColor),
      );
    } else {
      decoration = BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      );
    }

    return Container(
      padding: padding ?? componentTokens.padding,
      decoration: decoration,
      child: Row(
        spacing: componentTokens.contentGap,
        children: [
          if (showSpinner)
            SizedBox(
              width: componentTokens.spinnerSize,
              height: componentTokens.spinnerSize,
              child: TilawaLoadingIndicator(
                centered: false,
                strokeWidth: componentTokens.spinnerStrokeWidth,
                color: foregroundColor,
              ),
            )
          else
            Icon(icon, color: foregroundColor),
          Expanded(
            child: Semantics(
              // fix: Accessibility — announce transient feedback updates
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
