import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Foreground colors for the next-prayer card.
@immutable
class HomePrayerHeroForegroundStyle {
  const HomePrayerHeroForegroundStyle({
    required this.ink,
    required this.muted,
    required this.chipBackground,
    required this.chipBorder,
  });

  final Color ink;
  final Color muted;
  final Color chipBackground;
  final Color chipBorder;

  factory HomePrayerHeroForegroundStyle.fallback({
    required ColorScheme colorScheme,
    required TilawaHomeScreenTokens screenTokens,
  }) {
    return HomePrayerHeroForegroundStyle(
      ink: colorScheme.onSurface,
      muted: screenTokens.homeHeaderSecondaryText,
      chipBackground: screenTokens.homeHeaderChipBackground,
      chipBorder: Color.alphaBlend(
        screenTokens.homePrayerHeroBorder.withValues(alpha: 0.72),
        colorScheme.outlineVariant.withValues(alpha: 0.28),
      ),
    );
  }
}
