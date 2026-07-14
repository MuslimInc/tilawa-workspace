import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Soft Behance-style pastels for Home daily-worship cards.
///
/// Accents come from [MeMuslimProductColors.exploreFeatureIcon] (no new hex).
/// Washes stay light so the prayer hero remains the strongest Home surface.
abstract final class HomeFeaturePastel {
  const HomeFeaturePastel._();

  /// Card body tint — visible pastel, still calm (~14%).
  static const double surfaceTintAlpha = 0.14;

  /// Icon well — slightly stronger than the card wash (~22%).
  static const double iconWellFillAlpha = 0.22;

  static Color wash({
    required Color accent,
    required ColorScheme colorScheme,
  }) {
    return Color.alphaBlend(
      accent.withValues(alpha: surfaceTintAlpha),
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
