import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home dashboard elevation tiers — one shadow language across zones.
enum HomeDashboardElevationTier {
  /// Prayer hero — deepest lift ([MeMuslimElevationX.elevationFloating]).
  hero,

  /// Primary action cards and Smart Khatma entry.
  primary,

  /// Inspiration and passive content cards.
  inspiration,

  /// Quick tools row — lightest resting shadow.
  quickTool,

  /// More list — hairline only, no shadow.
  moreList,
}

/// Dashboard card surface — fill, hairline border, tiered shadow.
abstract final class HomeDashboardElevatedSurface {
  const HomeDashboardElevatedSurface._();

  static List<BoxShadow> shadows(
    BuildContext context,
    HomeDashboardElevationTier tier,
  ) {
    if (tier == HomeDashboardElevationTier.moreList) {
      return const <BoxShadow>[];
    }

    final MeMuslimDesignTokens tokens = context.tokens;
    final Color tint = Theme.of(context).colorScheme.shadow;

    return switch (tier) {
      HomeDashboardElevationTier.hero => tokens.elevationFloating(tint),
      HomeDashboardElevationTier.primary ||
      HomeDashboardElevationTier.inspiration => tokens.elevationRaised(tint),
      HomeDashboardElevationTier.quickTool => tokens.elevationSubtle(tint),
      HomeDashboardElevationTier.moreList => const <BoxShadow>[],
    };
  }

  static BoxDecoration decoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? color,
    HomeDashboardElevationTier tier = HomeDashboardElevationTier.primary,
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
          boxShadow: shadows(context, tier),
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
    HomeDashboardElevationTier tier = HomeDashboardElevationTier.primary,
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
        boxShadow: shadows(context, tier),
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
