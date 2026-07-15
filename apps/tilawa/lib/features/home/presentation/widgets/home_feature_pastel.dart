import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home daily-worship tile accents + quiet status chrome.
///
/// Card **bodies** stay [ColorScheme.surface] (white elevated cards — DESIGN
/// 60-30-10). Category hue lives only in icon wells / soft status chips so
/// the prayer hero remains the strongest colored surface.
abstract final class HomeFeaturePastel {
  const HomeFeaturePastel._();

  /// Resting card fill — elevated white, same language as More list rows.
  static Color cardSurface(ColorScheme colorScheme) => colorScheme.surface;

  /// Icon well — soft accent chip on white (readable, not a full-card wash).
  static const double iconWellFillAlpha = 0.16;

  /// Soft status-chip fill — finance-app pattern: tint the pill, not the card.
  static const double statusChipFillAlpha = 0.12;

  /// Soft [TilawaStatusChip] background on white.
  static Color statusChipBackground({
    required Color accent,
    required ColorScheme colorScheme,
  }) {
    return Color.alphaBlend(
      accent.withValues(alpha: statusChipFillAlpha),
      colorScheme.surface,
    );
  }

  /// Home shortcut accent for [feature].
  ///
  /// Tasbeeh uses the ceremonial featured warm stop so it separates visually
  /// from Reciters green (explore map uses nearby greens for both).
  static Color accentFor(
    HomeExploreFeature feature,
    MeMuslimProductColors product,
  ) {
    return switch (feature) {
      HomeExploreFeature.tasbeeh => product.featuredGradientEnd,
      _ => product.exploreFeatureIcon(feature),
    };
  }
}
