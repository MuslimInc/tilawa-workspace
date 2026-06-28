import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';

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
/// When [onTap] is provided the card is wrapped in [TilawaInteractiveSurface],
/// so blank/card navigation areas get the kit's shared soft ink splash,
/// highlight, and state-layer press feedback, keyboard focus ring, and haptic on
/// activation (no press-scale). Nested interactive widgets (buttons, menus,
/// icon-buttons) receive taps before the card's [onTap] and keep their own
/// pressed feedback — the card does not show a pressed wash when a nested
/// control is pressed.
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
    @Deprecated(
      'Prefer theme tokens — splashColor is forwarded to '
      'TilawaInteractiveSurface when set.',
    )
    this.splashColor,
    @Deprecated(
      'Prefer theme tokens — highlightColor is forwarded to '
      'TilawaInteractiveSurface when set.',
    )
    this.highlightColor,
    this.expandHeight = false,
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

  /// Optional override for [TilawaInteractiveSurface.splashColor].
  @Deprecated('Prefer theme tokens — forwarded when set.')
  final Color? splashColor;

  /// Optional override for [TilawaInteractiveSurface.highlightColor].
  @Deprecated('Prefer theme tokens — forwarded when set.')
  final Color? highlightColor;

  /// When true, expands to the maximum height offered by the parent.
  final bool expandHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaCardTokens tokens = theme.componentTokens.card;
    final MeMuslimDesignTokens designTokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    final double effectiveRadius =
        borderRadius ??
        designTokens.resolveRadius(family: TilawaRadiusFamily.card);
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

    final Widget paddingChild = Padding(
      padding: padding ?? tokens.padding,
      child: child,
    );

    final Widget surfaceWidget;
    if (onTap == null) {
      final Widget cardBody = Material(
        color: resolvedFill,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: paddingChild,
      );
      surfaceWidget = hasShadow
          ? _TilawaCardShadow(
              borderRadius: borderRadiusValue,
              designTokens: designTokens,
              colorScheme: colorScheme,
              child: cardBody,
            )
          : cardBody;
    } else {
      // Interactive cards route through the kit's single interaction primitive.
      // The surface owns the Material fill so ink splash/highlight render on
      // the card face (not behind an opaque child).
      final Widget interactiveCore = TilawaInteractiveSurface(
        onTap: onTap,
        borderRadius: borderRadiusValue,
        materialColor: resolvedFill,
        materialShape: shape,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: paddingChild,
      );
      surfaceWidget = hasShadow
          ? _TilawaCardShadow(
              borderRadius: borderRadiusValue,
              designTokens: designTokens,
              colorScheme: colorScheme,
              child: interactiveCore,
            )
          : interactiveCore;
    }

    return SizedBox(
      width: double.infinity,
      height: expandHeight ? double.infinity : null,
      child: surfaceWidget,
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
  final MeMuslimDesignTokens designTokens;
  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
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
