import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Hero foreground tokens and legibility helpers for phase gradients.
abstract final class HomeHeroPhotoTheme {
  const HomeHeroPhotoTheme._();

  /// Sample luminance for contrast decisions on the hero ramp.
  static double heroSampleLuminance(TilawaHomeNextPrayerHeroTokens tokens) {
    return Color.lerp(
      tokens.gradientTopStart,
      tokens.gradientBottomEnd,
      0.42,
    )!.computeLuminance();
  }

  /// True when the hero ramp is dark enough for cream foreground.
  static bool isDarkHero(TilawaHomeNextPrayerHeroTokens tokens) {
    return heroSampleLuminance(tokens) < 0.52;
  }

  /// Ink for frosted glass card copy — always readable on white surface.
  static Color glassCardInk(ColorScheme scheme) => scheme.onSurface;

  /// Muted ink for secondary lines inside the frosted card.
  static Color glassCardMuted(ColorScheme scheme) => scheme.onSurfaceVariant;

  /// Ink for Hijri date and hero chrome on the gradient ramp.
  static Color heroChromeInk(TilawaHomeNextPrayerHeroTokens tokens) {
    return isDarkHero(tokens)
        ? tokens.foregroundColor
        : AppColors.homeNextPrayerGradientForeground;
  }

  /// Muted hero chrome ink for secondary gradient copy.
  static Color heroChromeMuted(
    TilawaHomeNextPrayerHeroTokens tokens, {
    required double opacity,
  }) {
    return heroChromeInk(tokens).withValues(alpha: opacity);
  }

  /// Collapsed toolbar copy over the pinned hero bar.
  static Color collapsedToolbarForeground({
    required Color collapsedBarColor,
    required TilawaHomeNextPrayerHeroTokens heroTokens,
  }) {
    return collapsedBarColor.computeLuminance() > 0.52
        ? AppColors.tripGlideInk
        : heroTokens.foregroundColor;
  }

  /// Keeps phase [foregroundColor] (ink on light canvas) with tuned opacities.
  static TilawaHomeNextPrayerHeroTokens adapt(
    TilawaHomeNextPrayerHeroTokens base,
  ) {
    return base.copyWith(
      mutedForegroundOpacity: 0.72,
      tertiaryForegroundOpacity: 0.68,
      footerForegroundOpacity: 0.92,
      locationChipFillOpacity: 0.08,
      locationChipBorderOpacity: 0.20,
      locationChipSplashOpacity: 0.10,
      locationChipHighlightOpacity: 0.05,
    );
  }

  static List<Shadow> textShadows(
    Color foreground,
    TilawaDesignTokens tokens,
  ) {
    if (foreground.computeLuminance() > 0.45) {
      return const <Shadow>[];
    }
    return <Shadow>[
      Shadow(
        color: Colors.black.withValues(alpha: 0.32),
        blurRadius: tokens.blurShadow * 1.5,
        offset: Offset(0, tokens.shadowOffsetSmall.dy),
      ),
    ];
  }

  static TextStyle? labelStyle(
    TextStyle? base,
    Color color, {
    required TilawaDesignTokens tokens,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return base?.copyWith(
      color: color,
      fontWeight: fontWeight,
      shadows: textShadows(color, tokens),
    );
  }

  static TextStyle? titleStyle(
    TextStyle? base,
    Color color, {
    required TilawaDesignTokens tokens,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return base?.copyWith(
      color: color,
      fontWeight: fontWeight,
      height: 1.1,
      shadows: textShadows(color, tokens),
    );
  }
}
