import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home daily-worship tile accents + quiet status chrome.
///
/// Card surface ladder (Ngajii / Dribbble Islamic-home contrast):
/// 1. Prayer hero — solid primary (strongest green)
/// 2. Mushaf / Athkar / quick tools — elevated white + solid accent icon wells
/// 3. Featured habit (Khatma) — elevated white + focused green progress/CTA
/// 4. More list — elevated white hairline rows
///
/// Solid green stays on the hero, icon wells, progress, and primary CTAs — not
/// on every card body.
abstract final class HomeFeaturePastel {
  const HomeFeaturePastel._();

  /// Soft wash helper default (legacy ceremonial tint).
  static const double primaryWorshipWashAlpha = 0.10;

  /// Soft wash for rare tool tints (prefer white + solid wells).
  static const double toolWashAlpha = 0.055;

  /// Soft accent chip on white (Learn / resume / secondary chrome).
  static const double iconWellFillAlpha = 0.16;

  /// Ngajii-style solid icon well on white cards.
  static const double solidIconWellFillAlpha = 1.0;

  /// Soft status-chip fill — tint the pill, not the card.
  static const double statusChipFillAlpha = 0.12;

  /// Khatma summary header: visible mint at the leading edge, near-white at end.
  static const double featuredHeaderStartAlpha = 0.14;
  static const double featuredHeaderEndAlpha = 0.04;

  /// Resting card fill — elevated white (Mushaf, Athkar, tools, More).
  static Color cardSurface(ColorScheme colorScheme) => colorScheme.surface;

  /// Airy Khatma header inspired by travel-card dashboards: mint into white.
  static LinearGradient featuredHeaderGradient({
    required Color accent,
    required ColorScheme colorScheme,
  }) {
    final Color surface = cardSurface(colorScheme);
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: <Color>[
        Color.alphaBlend(
          accent.withValues(alpha: featuredHeaderStartAlpha),
          surface,
        ),
        Color.alphaBlend(
          accent.withValues(alpha: featuredHeaderEndAlpha),
          surface,
        ),
      ],
    );
  }

  /// Soft parchment / mint wash.
  static Color ceremonialWash({
    required Color accent,
    required ColorScheme colorScheme,
    double alpha = primaryWorshipWashAlpha,
  }) {
    return Color.alphaBlend(
      accent.withValues(alpha: alpha),
      colorScheme.surface,
    );
  }

  /// Mushaf / Athkar tile bodies — white (solid accent lives in the icon well).
  static Color primaryWorshipSurface({
    required Color accent,
    required ColorScheme colorScheme,
  }) {
    return cardSurface(colorScheme);
  }

  /// Quick-tool tile bodies — white (pastel lives in solid category wells).
  static Color toolWash({
    required Color accent,
    required ColorScheme colorScheme,
  }) {
    return cardSurface(colorScheme);
  }

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
