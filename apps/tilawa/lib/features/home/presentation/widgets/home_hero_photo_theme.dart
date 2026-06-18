import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Photo-hero foreground tokens and legibility helpers.
abstract final class HomeHeroPhotoTheme {
  const HomeHeroPhotoTheme._();

  static TilawaHomeNextPrayerHeroTokens adapt(
    TilawaHomeNextPrayerHeroTokens base,
  ) {
    return base.copyWith(
      foregroundColor: Colors.white,
      mutedForegroundOpacity: 0.84,
      tertiaryForegroundOpacity: 0.78,
      footerForegroundOpacity: 0.96,
      locationChipFillOpacity: 0.16,
      locationChipBorderOpacity: 0.34,
      locationChipSplashOpacity: 0.14,
      locationChipHighlightOpacity: 0.08,
    );
  }

  static List<Shadow> textShadows(TilawaDesignTokens tokens) {
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
      shadows: textShadows(tokens),
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
      shadows: textShadows(tokens),
    );
  }
}
