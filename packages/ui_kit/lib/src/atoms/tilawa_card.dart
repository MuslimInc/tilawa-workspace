import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// A foundational card component with standardized styling.
///
/// Reads default values from [TilawaCardTokens] for consistent
/// radius, border width, and padding across the application.
///
/// By default the card carries a soft drop shadow tuned for visibility
/// on real-device DPIs (~400 ppi). Pass `flat: true` for cards that are
/// nested inside another elevated surface (e.g. rows inside a settings
/// group) to avoid double-shadowing.
class TilawaCard extends StatelessWidget {
  const TilawaCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.gradient,
    this.onTap,
    this.splashColor,
    this.highlightColor,
    this.flat = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Color? splashColor;
  final Color? highlightColor;

  /// When true, suppresses the default drop shadow. Use for cards nested
  /// inside another already-elevated container.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.card;
    final designTokens = theme.tokens;

    final double effectiveRadius = borderRadius ?? tokens.borderRadius;
    final BorderRadius borderRadiusValue = BorderRadius.circular(
      effectiveRadius,
    );
    final BoxDecoration decoration = BoxDecoration(
      color: gradient == null
          ? (backgroundColor ?? theme.colorScheme.surface)
          : null,
      gradient: gradient,
      borderRadius: borderRadiusValue,
      border: Border.all(
        color: borderColor ?? theme.colorScheme.outlineVariant,
        width: borderWidth ?? tokens.borderWidth,
      ),
      boxShadow: flat
          ? null
          : [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                  alpha: designTokens.opacityShadow,
                ),
                blurRadius: designTokens.blurShadow,
                offset: designTokens.shadowOffsetSmall,
              ),
            ],
    );

    final Widget content = Container(
      decoration: decoration,
      child: Padding(padding: padding ?? tokens.padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    final effectiveSplashColor =
        splashColor ??
        theme.colorScheme.primary.withValues(alpha: designTokens.opacitySubtle);
    final effectiveHighlightColor =
        highlightColor ??
        theme.colorScheme.onSurface.withValues(
          alpha: designTokens.opacitySubtle / 2,
        );

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: borderRadiusValue,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadiusValue,
          splashColor: effectiveSplashColor,
          highlightColor: effectiveHighlightColor,
          child: Padding(padding: padding ?? tokens.padding, child: child),
        ),
      ),
    );
  }
}
