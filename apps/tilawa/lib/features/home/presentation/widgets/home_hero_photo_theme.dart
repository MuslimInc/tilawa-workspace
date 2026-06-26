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
    return tokens.foregroundColor;
  }

  /// Muted hero chrome ink for secondary gradient copy.
  static Color heroChromeMuted(
    TilawaHomeNextPrayerHeroTokens tokens, {
    required double opacity,
  }) {
    return heroChromeInk(tokens).withValues(alpha: opacity);
  }

  /// Collapsed toolbar copy over the pinned premium hero bar.
  static Color collapsedToolbarForeground({
    required ColorScheme colorScheme,
  }) {
    return colorScheme.onSurface;
  }

  /// Muted collapsed-toolbar ink on the pinned premium bar.
  static Color collapsedToolbarMuted(ColorScheme colorScheme) {
    return colorScheme.onSurfaceVariant;
  }

  /// Representative fill for status-bar contrast and [Material] underlay.
  static Color collapsedBarSampleColor(
    TilawaHomeScreenTokens screenTokens,
  ) {
    return screenTokens.homeCollapsedHeaderFill;
  }

  /// Status bar icons when the hero is fully pinned on primary.
  static SystemUiOverlayStyle collapsedBarOverlayStyle(
    Color collapsedBarColor,
  ) {
    return collapsedBarColor.computeLuminance() > 0.52
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
  }

  /// Premium wash for the pinned hero bar — canvas-aware frosted surface.
  static BoxDecoration collapsedBarSurfaceDecoration({
    required ColorScheme colorScheme,
    required MeMuslimDesignTokens tokens,
    required TilawaHomeScreenTokens screenTokens,
  }) {
    return BoxDecoration(
      color: screenTokens.homeCollapsedHeaderFill,
      border: Border(
        bottom: BorderSide(
          color: screenTokens.homeCollapsedHeaderBorder,
          width: tokens.borderWidthThin,
        ),
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(
            alpha: screenTokens.homeCollapsedHeaderShadowOpacity,
          ),
          offset: tokens.shadowOffsetSmall,
          blurRadius: tokens.spaceSmall.toDouble(),
        ),
      ],
    );
  }

  /// Soft top-inner highlight on pinned premium chrome.
  static BoxDecoration collapsedBarInnerHighlight({
    required ColorScheme colorScheme,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topCenter,
        end: AlignmentDirectional.bottomCenter,
        colors: <Color>[
          colorScheme.onSurface.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.22],
      ),
    );
  }

  /// Zone divider between pinned-toolbar columns.
  static Color collapsedToolbarDividerColor(ColorScheme colorScheme) {
    return colorScheme.outlineVariant.withValues(alpha: 0.72);
  }

  /// Location chip on the pinned premium toolbar.
  static BoxDecoration collapsedLocationChipDecoration({
    required ColorScheme colorScheme,
    required MeMuslimDesignTokens tokens,
  }) {
    return BoxDecoration(
      color: colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );
  }

  /// Countdown pill on the pinned premium toolbar.
  static BoxDecoration collapsedCountdownChipDecoration({
    required ColorScheme colorScheme,
    required MeMuslimDesignTokens tokens,
  }) {
    return BoxDecoration(
      color: colorScheme.semanticTintBackground(TilawaSemanticTint.gilding),
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.45),
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
    MeMuslimDesignTokens tokens, {
    required Color shadowColor,
  }) {
    if (foreground.computeLuminance() > 0.45) {
      return const <Shadow>[];
    }
    return <Shadow>[
      Shadow(
        color: shadowColor.withValues(alpha: 0.32),
        blurRadius: tokens.blurShadow * 1.5,
        offset: Offset(0, tokens.shadowOffsetSmall.dy),
      ),
    ];
  }

  static TextStyle? labelStyle(
    TextStyle? base,
    Color color, {
    required MeMuslimDesignTokens tokens,
    required ColorScheme colorScheme,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return base?.copyWith(
      color: color,
      fontWeight: fontWeight,
      shadows: textShadows(
        color,
        tokens,
        shadowColor: colorScheme.scrim,
      ),
    );
  }

  static TextStyle? titleStyle(
    TextStyle? base,
    Color color, {
    required MeMuslimDesignTokens tokens,
    required ColorScheme colorScheme,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return base?.copyWith(
      color: color,
      fontWeight: fontWeight,
      height: 1.1,
      shadows: textShadows(
        color,
        tokens,
        shadowColor: colorScheme.scrim,
      ),
    );
  }
}
