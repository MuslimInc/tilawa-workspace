import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Reference-style elevated white card for the Home dashboard.
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

    return BoxDecoration(
      color: screenTokens.homeContentSheetSurface,
      borderRadius: resolved,
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(
            alpha: screenTokens.homePrayerHeroShadowOpacity,
          ),
          offset: Offset(0, tokens.spaceExtraSmall.toDouble()),
          blurRadius: tokens.spaceLarge.toDouble(),
        ),
      ],
    );
  }
}
