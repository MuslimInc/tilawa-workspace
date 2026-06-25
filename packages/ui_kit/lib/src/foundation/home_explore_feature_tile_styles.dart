import 'package:flutter/material.dart';

import 'semantic_tints.dart';
import 'memuslim_product_colors.dart';

/// Home Discover grid features — one id per explore tile.
enum HomeExploreFeature {
  reciters,
  athkar,
  prayer,
  qibla,
  tasbeeh,
  bookmarks,
  quran,
  support,
  sessions,
}

/// Resolved icon styling for a [HomeExploreFeature] category tile.
///
/// Tile fill is shared — see [HomeExploreFeatureTileStyles.homeExploreTileBackground].
@immutable
class HomeExploreFeatureTileStyle {
  const HomeExploreFeatureTileStyle({
    required this.iconForeground,
    this.semanticTint = TilawaSemanticTint.neutral,
  });

  final Color iconForeground;
  final TilawaSemanticTint semanticTint;
}

/// Per-feature Discover grid colors — neutral tiles, category accent glyphs.
extension HomeExploreFeatureTileStyles on ColorScheme {
  /// Subtle teal-tinted fill shared by every Home explore tile.
  Color get homeExploreTileBackground {
    final double warmth = brightness == Brightness.dark ? 0.10 : 0.06;
    return Color.alphaBlend(
      primary.withValues(alpha: warmth),
      surfaceContainerHigh,
    );
  }

  /// Icon color (+ optional semantic role) for one [HomeExploreFeature] tile.
  HomeExploreFeatureTileStyle homeExploreFeatureTileStyle(
    HomeExploreFeature feature,
  ) {
    final MeMuslimProductColors product = brightness == Brightness.dark
        ? MeMuslimProductColors.dark(this)
        : MeMuslimProductColors.light(this);
    return product.exploreFeatureTileStyle(feature);
  }
}
