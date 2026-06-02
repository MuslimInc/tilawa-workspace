import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Surface treatment applied to a [TilawaCard].
///
/// The Tilawa visual system uses a small set of *calm* card surfaces.
/// Cards do not stack borders + gradients + shadows — pick one treatment.
enum TilawaCardSurface {
  /// Solid `surface` colour with a hairline outline and a soft drop shadow.
  ///
  /// Default top-level card on a scaffold background.
  raised,

  /// Solid `surface` colour with a hairline outline and **no** shadow.
  ///
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
/// and an optional soft shadow via [TilawaCardSurface].
///
/// ## Interactive children
///
/// When [onTap] is provided the card uses a [Material] + [InkWell] pair so
/// ripples render on the card surface. Nested interactive widgets (buttons,
/// menus, icon-buttons) receive taps before the card's [onTap] because they
/// sit in the [InkWell] child subtree.
///
/// If an interactive control needs a *different* action from the card's
/// [onTap] (e.g. a delete button alongside a navigation card), place it as
/// a sibling of [TilawaCard] in an outer [Row] rather than inside [child].
/// This is the pattern used by `BookmarkCard`, `HistoryCard`,
/// `PlaylistCard`, and `TasbeehScreen`'s history list.
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaCardTokens tokens = theme.componentTokens.card;
    final TilawaDesignTokens designTokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    final double effectiveRadius = borderRadius ?? tokens.borderRadius;
    final BorderRadius borderRadiusValue = BorderRadius.circular(
      effectiveRadius,
    );

    final bool isOutline = surface == TilawaCardSurface.outline;
    final bool hasShadow = surface == TilawaCardSurface.raised;

    final Color resolvedFill = isOutline
        ? Colors.transparent
        : (backgroundColor ?? colorScheme.surface);

    final BorderSide borderSide = BorderSide(
      color: borderColor ?? colorScheme.outlineVariant,
      width: borderWidth ?? tokens.borderWidth,
    );

    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: borderRadiusValue,
      side: borderSide,
    );

    final Widget surfaceWidget = _TilawaCardSolidSurface(
      fillColor: resolvedFill,
      shape: shape,
      borderRadius: borderRadiusValue,
      onTap: onTap,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: padding ?? tokens.padding,
        child: child,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: hasShadow
          ? _TilawaCardShadow(
              borderRadius: borderRadiusValue,
              designTokens: designTokens,
              colorScheme: colorScheme,
              child: surfaceWidget,
            )
          : surfaceWidget,
    );
  }
}

class _TilawaCardShadow extends StatelessWidget {
  const _TilawaCardShadow({
    required this.borderRadius,
    required this.designTokens,
    required this.colorScheme,
    required this.child,
  });

  final BorderRadius borderRadius;
  final TilawaDesignTokens designTokens;
  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          // Ambient layer: tight, low-opacity — gives the card a "lifted off
          // surface" feel at close range even when the directional shadow is subtle.
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: designTokens.opacityShadow * 0.55,
            ),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          // Directional layer: larger blur, slightly stronger — the main
          // perceived depth cue from overhead ambient light.
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: designTokens.opacityShadow,
            ),
            blurRadius: designTokens.blurShadow,
            offset: designTokens.shadowOffsetMedium,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TilawaCardSolidSurface extends StatelessWidget {
  const _TilawaCardSolidSurface({
    required this.fillColor,
    required this.shape,
    required this.borderRadius,
    required this.onTap,
    required this.splashColor,
    required this.highlightColor,
    required this.child,
  });

  final Color fillColor;
  final ShapeBorder shape;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final Color? splashColor;
  final Color? highlightColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: _TilawaCardInkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: child,
      ),
    );
  }
}

class _TilawaCardInkWell extends StatelessWidget {
  const _TilawaCardInkWell({
    required this.onTap,
    required this.borderRadius,
    required this.splashColor,
    required this.highlightColor,
    required this.child,
  });

  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return child;
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TilawaDesignTokens designTokens = Theme.of(context).tokens;

    final Color effectiveSplashColor =
        splashColor ??
        colorScheme.primary.withValues(alpha: designTokens.opacitySubtle);
    final Color effectiveHighlightColor =
        highlightColor ??
        colorScheme.onSurface.withValues(
          alpha: designTokens.opacitySubtle / 2,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      splashColor: effectiveSplashColor,
      highlightColor: effectiveHighlightColor,
      child: child,
    );
  }
}
