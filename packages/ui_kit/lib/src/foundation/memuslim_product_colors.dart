import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'home_explore_feature_tile_styles.dart';
import 'semantic_tints.dart';

/// Product-specific semantic colours for MeMuslim features.
///
/// Feature widgets should read roles from [ThemeData.productColors] (or
/// [ColorScheme] / [MeMuslimComponentTokens] for generic chrome) — not from
/// [AppColors] directly. Hex values are assembled here from the palette in
/// [AppColors]; see `docs/design/color_architecture.md`.
@immutable
class MeMuslimProductColors extends ThemeExtension<MeMuslimProductColors> {
  const MeMuslimProductColors({
    required this.brandLockedPrimary,
    required this.brandLockedOnPrimary,
    required this.prayerTimeActive,
    required this.prayerTimeNext,
    required this.prayerTimeNextSurface,
    required this.quranPageBackground,
    required this.quranTextPrimary,
    required this.quranTextSecondary,
    required this.playerBackground,
    required this.playerProgress,
    required this.athkarCounter,
    required this.info,
    required this.featuredGradientStart,
    required this.featuredGradientEnd,
    required this.featuredGradientForeground,
  });

  /// Splash / login accent — always the brand-locked primary, not user picker.
  final Color brandLockedPrimary;

  /// Foreground on [brandLockedPrimary].
  final Color brandLockedOnPrimary;

  /// Accent for the current / highlighted prayer row.
  final Color prayerTimeActive;

  /// Emphasis for the next upcoming prayer (icons, labels).
  final Color prayerTimeNext;

  /// Fill behind the next-prayer card row.
  final Color prayerTimeNextSurface;

  /// Mushaf page canvas — calm, high-contrast reading surface.
  final Color quranPageBackground;

  /// Verse and primary reader text.
  final Color quranTextPrimary;

  /// Metadata, range labels, secondary reader copy.
  final Color quranTextSecondary;

  /// Expanded player shell background.
  final Color playerBackground;

  /// Playback progress fill.
  final Color playerProgress;

  /// Tasbeeh counter ring and emphasis.
  final Color athkarCounter;

  /// Neutral informational accent (sessions, metadata chips).
  final Color info;

  /// Featured / ceremonial card gradient stops (Home Last Read, pinned athkar).
  final Color featuredGradientStart;

  final Color featuredGradientEnd;

  final Color featuredGradientForeground;

  factory MeMuslimProductColors.light(ColorScheme scheme) {
    return MeMuslimProductColors(
      brandLockedPrimary: AppColors.defaultPrimary,
      brandLockedOnPrimary: AppColors.lightSchemeOnPrimary,
      prayerTimeActive: scheme.primary,
      prayerTimeNext: scheme.primary,
      prayerTimeNextSurface: scheme.primaryContainer,
      quranPageBackground: AppQuranReaderLegacyColors.lightPageBackground,
      quranTextPrimary: AppQuranReaderLegacyColors.lightOnSurface,
      quranTextSecondary: AppQuranReaderLegacyColors.lightMutedOnSurface,
      playerBackground: scheme.surfaceContainerLow,
      playerProgress: scheme.primary,
      athkarCounter: scheme.primary,
      info: AppColors.categoryAccentBlueGrey,
      featuredGradientStart: AppColors.featuredGradientStart,
      featuredGradientEnd: AppColors.featuredGradientEnd,
      featuredGradientForeground: AppColors.featuredGradientForeground,
    );
  }

  factory MeMuslimProductColors.dark(ColorScheme scheme) {
    return MeMuslimProductColors(
      brandLockedPrimary: AppColors.darkDefaultPrimary,
      brandLockedOnPrimary: AppColors.lightSchemeOnPrimary,
      prayerTimeActive: scheme.primary,
      prayerTimeNext: scheme.primary,
      prayerTimeNextSurface: scheme.primaryContainer,
      quranPageBackground: AppQuranReaderLegacyColors.darkPageBackground,
      quranTextPrimary: AppQuranReaderLegacyColors.darkOnSurface,
      quranTextSecondary: AppQuranReaderLegacyColors.darkMutedCaption,
      playerBackground: scheme.surfaceContainer,
      playerProgress: scheme.primary,
      athkarCounter: scheme.primary,
      info: AppColors.categoryAccentBlueGrey,
      featuredGradientStart: AppColors.featuredGradientStart,
      featuredGradientEnd: AppColors.featuredGradientEnd,
      featuredGradientForeground:
          AppColors.homeNextPrayerGradientNightForeground,
    );
  }

  /// Hub explore grid icon colour for [feature].
  ///
  /// Centralises the former `categoryAccent*` literals so feature code never
  /// imports visual palette names.
  Color exploreFeatureIcon(HomeExploreFeature feature) {
    return switch (feature) {
      // Quiet green family + ceremonial gold — distinct per feature.
      HomeExploreFeature.reciters => AppColors.categoryAccentGreen,
      HomeExploreFeature.athkar => AppColors.categoryAccentOrange,
      HomeExploreFeature.prayer => prayerTimeActive,
      HomeExploreFeature.qibla => AppColors.categoryAccentBlue,
      HomeExploreFeature.tasbeeh => AppColors.brandGoldAccent,
      HomeExploreFeature.bookmarks => AppColors.categoryAccentIndigo,
      HomeExploreFeature.quran => AppColors.categoryAccentAmber,
      HomeExploreFeature.support => AppColors.brandActionGreenAccessible,
      HomeExploreFeature.sessions => AppColors.categoryAccentBlueGrey,
      HomeExploreFeature.reels => AppColors.categoryAccentIndigo,
    };
  }

  TilawaSemanticTint exploreFeatureSemanticTint(HomeExploreFeature feature) {
    return switch (feature) {
      HomeExploreFeature.reciters => TilawaSemanticTint.scholar,
      HomeExploreFeature.athkar => TilawaSemanticTint.caution,
      HomeExploreFeature.prayer => TilawaSemanticTint.ink,
      HomeExploreFeature.qibla => TilawaSemanticTint.parchment,
      HomeExploreFeature.tasbeeh => TilawaSemanticTint.gilding,
      HomeExploreFeature.bookmarks => TilawaSemanticTint.ink,
      HomeExploreFeature.quran => TilawaSemanticTint.gilding,
      HomeExploreFeature.support => TilawaSemanticTint.success,
      HomeExploreFeature.sessions => TilawaSemanticTint.scholar,
      HomeExploreFeature.reels => TilawaSemanticTint.scholar,
    };
  }

  HomeExploreFeatureTileStyle exploreFeatureTileStyle(
    HomeExploreFeature feature,
  ) {
    return HomeExploreFeatureTileStyle(
      iconForeground: exploreFeatureIcon(feature),
      semanticTint: exploreFeatureSemanticTint(feature),
    );
  }

  @override
  MeMuslimProductColors copyWith({
    Color? brandLockedPrimary,
    Color? brandLockedOnPrimary,
    Color? prayerTimeActive,
    Color? prayerTimeNext,
    Color? prayerTimeNextSurface,
    Color? quranPageBackground,
    Color? quranTextPrimary,
    Color? quranTextSecondary,
    Color? playerBackground,
    Color? playerProgress,
    Color? athkarCounter,
    Color? info,
    Color? featuredGradientStart,
    Color? featuredGradientEnd,
    Color? featuredGradientForeground,
  }) {
    return MeMuslimProductColors(
      brandLockedPrimary: brandLockedPrimary ?? this.brandLockedPrimary,
      brandLockedOnPrimary: brandLockedOnPrimary ?? this.brandLockedOnPrimary,
      prayerTimeActive: prayerTimeActive ?? this.prayerTimeActive,
      prayerTimeNext: prayerTimeNext ?? this.prayerTimeNext,
      prayerTimeNextSurface:
          prayerTimeNextSurface ?? this.prayerTimeNextSurface,
      quranPageBackground: quranPageBackground ?? this.quranPageBackground,
      quranTextPrimary: quranTextPrimary ?? this.quranTextPrimary,
      quranTextSecondary: quranTextSecondary ?? this.quranTextSecondary,
      playerBackground: playerBackground ?? this.playerBackground,
      playerProgress: playerProgress ?? this.playerProgress,
      athkarCounter: athkarCounter ?? this.athkarCounter,
      info: info ?? this.info,
      featuredGradientStart:
          featuredGradientStart ?? this.featuredGradientStart,
      featuredGradientEnd: featuredGradientEnd ?? this.featuredGradientEnd,
      featuredGradientForeground:
          featuredGradientForeground ?? this.featuredGradientForeground,
    );
  }

  @override
  MeMuslimProductColors lerp(MeMuslimProductColors? other, double t) {
    if (other is! MeMuslimProductColors) {
      return this;
    }
    Color? lerpColor(Color a, Color b) => Color.lerp(a, b, t);
    return MeMuslimProductColors(
      brandLockedPrimary: lerpColor(
        brandLockedPrimary,
        other.brandLockedPrimary,
      )!,
      brandLockedOnPrimary: lerpColor(
        brandLockedOnPrimary,
        other.brandLockedOnPrimary,
      )!,
      prayerTimeActive: lerpColor(prayerTimeActive, other.prayerTimeActive)!,
      prayerTimeNext: lerpColor(prayerTimeNext, other.prayerTimeNext)!,
      prayerTimeNextSurface: lerpColor(
        prayerTimeNextSurface,
        other.prayerTimeNextSurface,
      )!,
      quranPageBackground: lerpColor(
        quranPageBackground,
        other.quranPageBackground,
      )!,
      quranTextPrimary: lerpColor(quranTextPrimary, other.quranTextPrimary)!,
      quranTextSecondary: lerpColor(
        quranTextSecondary,
        other.quranTextSecondary,
      )!,
      playerBackground: lerpColor(playerBackground, other.playerBackground)!,
      playerProgress: lerpColor(playerProgress, other.playerProgress)!,
      athkarCounter: lerpColor(athkarCounter, other.athkarCounter)!,
      info: lerpColor(info, other.info)!,
      featuredGradientStart: lerpColor(
        featuredGradientStart,
        other.featuredGradientStart,
      )!,
      featuredGradientEnd: lerpColor(
        featuredGradientEnd,
        other.featuredGradientEnd,
      )!,
      featuredGradientForeground: lerpColor(
        featuredGradientForeground,
        other.featuredGradientForeground,
      )!,
    );
  }
}

/// Access [MeMuslimProductColors] from [ThemeData].
extension MeMuslimProductColorsX on ThemeData {
  MeMuslimProductColors get productColors {
    final MeMuslimProductColors? ext = extension<MeMuslimProductColors>();
    if (ext != null) {
      return ext;
    }
    return colorScheme.brightness == Brightness.dark
        ? MeMuslimProductColors.dark(colorScheme)
        : MeMuslimProductColors.light(colorScheme);
  }
}
