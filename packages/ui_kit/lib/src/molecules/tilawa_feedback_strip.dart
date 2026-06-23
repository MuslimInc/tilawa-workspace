import 'package:flutter/material.dart';

import '../atoms/tilawa_loading_indicator.dart';
import '../foundation/color_scheme_ext.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_feedback_strip_layout.dart';

/// Semantic intent for [TilawaFeedbackStrip] (affects a11y label + border).
enum TilawaFeedbackVariant {
  // fix: Feedback & states — structured info / warn / error presentation
  info,
  success,
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
    this.trailing,
    this.messageMaxLines,
    this.reserveMessageLines = false,
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

  /// Optional trailing controls (e.g. undo) after the message.
  final Widget? trailing;

  /// When set, clamps the message with [TextOverflow.ellipsis].
  final int? messageMaxLines;

  /// Reserves vertical space for [messageMaxLines] even when copy is shorter.
  final bool reserveMessageLines;

  static Color? _accentForVariant(
    BuildContext context,
    TilawaFeedbackVariant? v,
  ) {
    if (v == null) return null;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final tokens = theme.componentTokens.feedbackStrip;
    return switch (v) {
      TilawaFeedbackVariant.info => cs.outline.withValues(
        alpha: tokens.infoAccentOpacity,
      ),
      // Success and warning use their own hues so they are distinguishable
      // from error (and each other) by colour, not just opacity. Relying on
      // a single red at different alphas fails WCAG 1.4.1 (use of colour).
      TilawaFeedbackVariant.success => cs.success.withValues(
        alpha: tokens.successAccentOpacity,
      ),
      TilawaFeedbackVariant.warning => cs.warning.withValues(
        alpha: tokens.warningAccentOpacity,
      ),
      TilawaFeedbackVariant.error => cs.error.withValues(
        alpha: tokens.errorAccentOpacity,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.feedbackStrip;
    final designTokens = theme.tokens;
    final double radius =
        borderRadius ??
        designTokens.resolveRadius(family: TilawaRadiusFamily.chrome);
    final Color? accentColor =
        borderColor ?? _accentForVariant(context, variant);
    final TextStyle messageStyle = feedbackStripMessageStyle(
      context,
      foregroundColor: foregroundColor,
    );

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

    final int? maxLines = messageMaxLines;
    final double? contentMinHeight = maxLines != null && reserveMessageLines
        ? feedbackStripToastContentMinHeight(
            context,
            tokens: componentTokens,
            messageLineCount: maxLines,
            hasTrailing: trailing != null,
            messageStyle: messageStyle,
          )
        : null;

    Widget row = Row(
      spacing: componentTokens.contentGap,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LeadingSlot(
          icon: icon,
          foregroundColor: foregroundColor,
          showSpinner: showSpinner,
          size: componentTokens.leadingSlotSize,
          spinnerSize: componentTokens.spinnerSize,
          spinnerStrokeWidth: componentTokens.spinnerStrokeWidth,
        ),
        Expanded(
          child: Semantics(
            // fix: Accessibility — announce transient feedback updates
            liveRegion: true,
            child: Text(
              message,
              style: messageStyle,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              textAlign: TextAlign.start,
            ),
          ),
        ),
        ?trailing,
      ],
    );

    if (contentMinHeight != null) {
      row = ConstrainedBox(
        constraints: BoxConstraints(minHeight: contentMinHeight),
        child: row,
      );
    }

    return Container(
      padding: padding ?? componentTokens.padding,
      decoration: decoration,
      child: row,
    );
  }
}

class _LeadingSlot extends StatelessWidget {
  const _LeadingSlot({
    required this.icon,
    required this.foregroundColor,
    required this.showSpinner,
    required this.size,
    required this.spinnerSize,
    required this.spinnerStrokeWidth,
  });

  final IconData icon;
  final Color foregroundColor;
  final bool showSpinner;
  final double size;
  final double spinnerSize;
  final double spinnerStrokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: showSpinner
            ? SizedBox(
                width: spinnerSize,
                height: spinnerSize,
                child: TilawaLoadingIndicator(
                  centered: false,
                  strokeWidth: spinnerStrokeWidth,
                  color: foregroundColor,
                ),
              )
            : Icon(icon, color: foregroundColor, size: size),
      ),
    );
  }
}
