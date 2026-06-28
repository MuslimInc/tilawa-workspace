import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Flat dashboard surface — white fill, hairline border, optional soft shadow.
abstract final class HomeDashboardElevatedSurface {
  const HomeDashboardElevatedSurface._();

  static BoxDecoration decoration(
    BuildContext context, {
    BorderRadius? borderRadius,
  }) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final BorderRadius resolved =
        borderRadius ??
        BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.hero),
        );

    return screenTokens.dashboardSurfaceDecoration(
      tokens: tokens,
      colorScheme: theme.colorScheme,
      borderRadius: resolved,
    );
  }
}
