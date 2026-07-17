import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home daily-worship tile accents + quiet status chrome.
///
/// Card **bodies** stay elevated white by default (DESIGN 60-30-10). Primary
/// worship tiles may use a soft ceremonial wash via [ceremonialWash]. Category
/// hue lives in icon wells / soft status chips so the prayer countdown remains
/// the strongest green accent on the first viewport.
abstract final class HomeFeaturePastel {
  const HomeFeaturePastel._();

  /// Resting card fill — elevated white, same language as More list rows.
  static Color cardSurface(ColorScheme colorScheme) => colorScheme.surface;

  /// Soft parchment / mint wash for primary worship tiles.
  static Color ceremonialWash({
    required Color accent,
    required ColorScheme colorScheme,
    double alpha = 0.08,
  }) {
    return Color.alphaBlend(
      accent.withValues(alpha: alpha),
      colorScheme.surface,
    );
  }

  /// Soft tinted fill for quick-tool tiles (quieter than primary wash).
  static Color toolWash({
    required Color accent,
    required ColorScheme colorScheme,
  }) {
    return ceremonialWash(
      accent: accent,
      colorScheme: colorScheme,
      alpha: 0.055,
    );
  }

  /// Icon well — soft accent chip on white (readable, not a full-card wash).
  static const double iconWellFillAlpha = 0.16;

  /// Soft status-chip fill — tint the pill, not the card.
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

  /// Home shortcut accent for [feature] — green family + ceremonial gold.
  static Color accentFor(
    HomeExploreFeature feature,
    MeMuslimProductColors product,
  ) {
    return product.exploreFeatureIcon(feature);
  }
}
