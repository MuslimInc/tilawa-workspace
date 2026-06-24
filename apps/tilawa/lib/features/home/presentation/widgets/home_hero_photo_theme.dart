import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Collapsed toolbar copy over the pinned primary hero bar.
  static Color collapsedToolbarForeground({
    required Color collapsedBarColor,
    required TilawaHomeNextPrayerHeroTokens heroTokens,
    required ColorScheme colorScheme,
  }) {
    return colorScheme.onPrimary;
  }

  /// Muted collapsed-toolbar ink on the pinned primary bar.
  static Color collapsedToolbarMuted(ColorScheme colorScheme) {
    return colorScheme.onPrimary.withValues(alpha: 0.72);
  }

  /// Status bar icons when the hero is fully pinned on primary.
  static SystemUiOverlayStyle collapsedBarOverlayStyle(
    Color collapsedBarColor,
  ) {
    return collapsedBarColor.computeLuminance() > 0.52
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
  }

  /// Brand primary fill for the pinned hero bar with elevation.
  static BoxDecoration collapsedBarSurfaceDecoration({
    required Color collapsedBarColor,
    required TilawaHomeNextPrayerHeroTokens heroTokens,
    required ColorScheme colorScheme,
    required TilawaDesignTokens tokens,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topCenter,
        end: AlignmentDirectional.bottomCenter,
        colors: <Color>[
          Color.lerp(
            colorScheme.primaryContainer,
            colorScheme.primary,
            0.42,
          )!,
          colorScheme.primary,
        ],
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: tokens.opacityShadow),
          blurRadius: tokens.blurShadow,
          offset: tokens.shadowOffsetSmall,
        ),
      ],
    );
  }

  /// Soft top-inner highlight on pinned primary chrome.
  static BoxDecoration collapsedBarInnerHighlight({
    required ColorScheme colorScheme,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topCenter,
        end: AlignmentDirectional.bottomCenter,
        colors: <Color>[
          colorScheme.onPrimary.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.22],
      ),
    );
  }

  /// Zone divider between pinned-toolbar columns.
  static Color collapsedToolbarDividerColor(ColorScheme colorScheme) {
    return colorScheme.onPrimary.withValues(alpha: 0.28);
  }

  /// Location chip on the pinned primary toolbar.
  static BoxDecoration collapsedLocationChipDecoration({
    required ColorScheme colorScheme,
    required TilawaDesignTokens tokens,
  }) {
    return BoxDecoration(
      color: colorScheme.onPrimary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      border: Border.all(
        color: colorScheme.onPrimary.withValues(alpha: 0.24),
      ),
    );
  }

  /// Countdown pill on the pinned primary toolbar.
  static BoxDecoration collapsedCountdownChipDecoration({
    required ColorScheme colorScheme,
    required TilawaDesignTokens tokens,
  }) {
    return BoxDecoration(
      color: colorScheme.semanticTintBackground(TilawaSemanticTint.gilding),
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      border: Border.all(
        color: colorScheme.onPrimary.withValues(alpha: 0.2),
      ),
    );
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
