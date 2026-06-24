import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'color_scheme_ext.dart';
import 'semantic_tints.dart';

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

/// Per-feature Discover grid colors — uniform cream tiles, colored glyphs.
extension HomeExploreFeatureTileStyles on ColorScheme {
  /// Warm manuscript cream shared by every Home explore tile.
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
    return switch (feature) {
      HomeExploreFeature.reciters => const HomeExploreFeatureTileStyle(
        iconForeground: AppColors.primarySage,
        semanticTint: TilawaSemanticTint.scholar,
      ),
      HomeExploreFeature.athkar => HomeExploreFeatureTileStyle(
        iconForeground: warning,
        semanticTint: TilawaSemanticTint.caution,
      ),
      HomeExploreFeature.prayer => HomeExploreFeatureTileStyle(
        iconForeground: primary,
        semanticTint: TilawaSemanticTint.ink,
      ),
      HomeExploreFeature.qibla => HomeExploreFeatureTileStyle(
        iconForeground: onSurfaceVariant,
        semanticTint: TilawaSemanticTint.parchment,
      ),
      HomeExploreFeature.tasbeeh => HomeExploreFeatureTileStyle(
        iconForeground: onTertiaryContainer,
        semanticTint: TilawaSemanticTint.gilding,
      ),
      HomeExploreFeature.bookmarks => const HomeExploreFeatureTileStyle(
        iconForeground: AppColors.primaryBrownDark,
        semanticTint: TilawaSemanticTint.ink,
      ),
      HomeExploreFeature.quran => HomeExploreFeatureTileStyle(
        iconForeground: _ceremonialGoldIconColor(),
        semanticTint: TilawaSemanticTint.gilding,
      ),
      HomeExploreFeature.support => HomeExploreFeatureTileStyle(
        iconForeground: success,
        semanticTint: TilawaSemanticTint.success,
      ),
    };
  }

  Color _ceremonialGoldIconColor() {
    return Color.lerp(
      AppColors.featuredGradientStart,
      AppColors.featuredGradientEnd,
      0.5,
    )!;
  }
}
