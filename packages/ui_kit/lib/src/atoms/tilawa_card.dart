import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Surface treatment applied to a [TilawaCard].
///
/// The Tilawa visual system uses a small set of *calm* card surfaces.
/// Cards do not stack borders + gradients + shadows — pick one treatment.
enum TilawaCardSurface {
  /// Solid `surface` colour with a hairline outline and a soft drop shadow.
  /// Default top-level card on a scaffold background.
  raised,

  /// Solid `surface` colour with a hairline outline and **no** shadow.
  /// Use when the card is nested inside another elevated container
  /// (e.g. rows inside a settings group) so depth doesn't double up.
  flat,

  /// Hairline outline only, transparent fill. Use sparingly when the card
  /// needs to recede into its parent background.
  outline,
}

/// A foundational card component with standardized styling.
///
/// Reads default values from [TilawaCardTokens] for consistent
/// radius, border width, and padding across the application.
///
/// Cards are intentionally flat: a solid surface tone, a hairline outline,
/// and an optional soft shadow. The legacy [gradient] property is kept for
/// migration only — pass [surface] instead.
class TilawaCard extends StatelessWidget {
  const TilawaCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.surface = TilawaCardSurface.raised,
    this.onTap,
    this.splashColor,
    this.highlightColor,
    @Deprecated(
      'Cards in the Tilawa visual system are flat. Use [surface] and '
      '[backgroundColor] instead. Gradients are reserved for the color '
      'picker tool and share/reel composer artwork.',
    )
    this.gradient,
    @Deprecated('Use `surface: TilawaCardSurface.flat` instead.')
    this.flat = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;

  /// Surface treatment for this card. See [TilawaCardSurface].
  final TilawaCardSurface surface;

  final VoidCallback? onTap;
  final Color? splashColor;
  final Color? highlightColor;

  /// Legacy gradient fill. Prefer flat surfaces; this is retained only so
  /// in-flight migrations don't break.
  final Gradient? gradient;

  /// Legacy flag. Prefer `surface: TilawaCardSurface.flat`.
  final bool flat;

  TilawaCardSurface get _effectiveSurface =>
      flat ? TilawaCardSurface.flat : surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.card;
    final designTokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final double effectiveRadius = borderRadius ?? tokens.borderRadius;
    final BorderRadius borderRadiusValue = BorderRadius.circular(
      effectiveRadius,
    );

    final TilawaCardSurface s = _effectiveSurface;
    final bool isOutline = s == TilawaCardSurface.outline;
    final bool hasShadow = s == TilawaCardSurface.raised && gradient == null;

    final Color resolvedFill = isOutline
        ? Colors.transparent
        : (backgroundColor ?? colorScheme.surface);

    final BoxDecoration decoration = BoxDecoration(
      color: gradient == null ? resolvedFill : null,
      gradient: gradient,
      borderRadius: borderRadiusValue,
      border: Border.all(
        color: borderColor ?? colorScheme.outlineVariant,
        width: borderWidth ?? tokens.borderWidth,
      ),
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: designTokens.opacityShadow,
                ),
                blurRadius: designTokens.blurShadow,
                offset: designTokens.shadowOffsetSmall,
              ),
            ]
          : null,
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
        colorScheme.primary.withValues(alpha: designTokens.opacitySubtle);
    final effectiveHighlightColor =
        highlightColor ??
        colorScheme.onSurface.withValues(alpha: designTokens.opacitySubtle / 2);

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
