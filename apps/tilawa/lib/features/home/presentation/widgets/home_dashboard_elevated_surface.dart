import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Dashboard card surface — fill, hairline border, [TilawaCard] raised shadow tier.
abstract final class HomeDashboardElevatedSurface {
  const HomeDashboardElevatedSurface._();

  static BoxDecoration decoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? color,
  }) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final BorderRadius resolved =
        borderRadius ??
        BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.hero),
        );

    return screenTokens
        .dashboardSurfaceDecoration(
          tokens: tokens,
          colorScheme: colorScheme,
          borderRadius: resolved,
          color: color,
        )
        .copyWith(
          boxShadow: tokens.elevationRaised(colorScheme.shadow),
        );
  }

  /// Interactive home card with shadow painted outside [TilawaInteractiveSurface].
  ///
  /// Mirrors [TilawaCard]'s raised shadow layering so elevation is not clipped
  /// by the surface's anti-alias [Material].
  static Widget interactive({
    required BuildContext context,
    required BorderRadius borderRadius,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    String? semanticLabel,
    Color? stateLayerColor,
    Color? color,
    bool button = true,
  }) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final BoxDecoration fill = screenTokens.dashboardSurfaceDecoration(
      tokens: tokens,
      colorScheme: colorScheme,
      borderRadius: borderRadius,
      color: color,
    );
    final BorderSide borderSide =
        fill.border?.top ??
        BorderSide(
          color: colorScheme.outlineVariant,
          width: tokens.borderWidthThin,
        );
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: borderSide,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: tokens.elevationRaised(colorScheme.shadow),
      ),
      child: TilawaInteractiveSurface(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        semanticLabel: semanticLabel,
        stateLayerColor: stateLayerColor,
        button: button,
        materialColor: fill.color ?? color ?? colorScheme.surface,
        materialShape: shape,
        child: child,
      ),
    );
  }
}
