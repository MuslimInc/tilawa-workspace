import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home daily-worship tile accents.
///
/// Card **bodies** stay [ColorScheme.surface] (white elevated cards — DESIGN
/// 60-30-10). Category hue lives only in the icon well / icon foreground so
/// the prayer hero remains the strongest colored surface and the dashboard
/// does not read as a candy pastel stack.
abstract final class HomeFeaturePastel {
  const HomeFeaturePastel._();

  /// Resting card fill — elevated white, same language as More list rows.
  static Color cardSurface(ColorScheme colorScheme) => colorScheme.surface;

  /// Icon well — soft accent chip on white (readable, not a full-card wash).
  static const double iconWellFillAlpha = 0.16;

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
