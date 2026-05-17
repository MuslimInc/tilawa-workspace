import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../design_tokens.dart' show kTilawaMinInteractiveDimension;
import 'token_lerp.dart';

@immutable
class TilawaPlayerBackgroundTokens {
  const TilawaPlayerBackgroundTokens({
    required this.cacheWidthScale,
    required this.defaultBlurAmount,
    required this.defaultOverlayOpacity,
    required this.overlayColor,
  });

  final double cacheWidthScale;
  final double defaultBlurAmount;
  final double defaultOverlayOpacity;
  final Color overlayColor;

  factory TilawaPlayerBackgroundTokens.defaults() {
    return const TilawaPlayerBackgroundTokens(
      cacheWidthScale: 2,
      defaultBlurAmount: 0,
      defaultOverlayOpacity: 0.4,
      overlayColor: Colors.black,
    );
  }

  TilawaPlayerBackgroundTokens copyWith({
    double? cacheWidthScale,
    double? defaultBlurAmount,
    double? defaultOverlayOpacity,
    Color? overlayColor,
  }) {
    return TilawaPlayerBackgroundTokens(
      cacheWidthScale: cacheWidthScale ?? this.cacheWidthScale,
      defaultBlurAmount: defaultBlurAmount ?? this.defaultBlurAmount,
      defaultOverlayOpacity:
          defaultOverlayOpacity ?? this.defaultOverlayOpacity,
      overlayColor: overlayColor ?? this.overlayColor,
    );
  }

  static TilawaPlayerBackgroundTokens lerp(
    TilawaPlayerBackgroundTokens a,
    TilawaPlayerBackgroundTokens b,
    double t,
  ) {
    return TilawaPlayerBackgroundTokens(
      cacheWidthScale: lerpTokenDouble(a.cacheWidthScale, b.cacheWidthScale, t),
      defaultBlurAmount: lerpTokenDouble(
        a.defaultBlurAmount,
        b.defaultBlurAmount,
        t,
      ),
      defaultOverlayOpacity: lerpTokenDouble(
        a.defaultOverlayOpacity,
        b.defaultOverlayOpacity,
        t,
      ),
      overlayColor: Color.lerp(a.overlayColor, b.overlayColor, t)!,
    );
  }
}

@immutable
class TilawaFooterBarTokens {
  const TilawaFooterBarTokens({
    required this.height,
    required this.horizontalPadding,
    required this.contentGap,
    required this.labelFontSize,
    required this.labelFontWeight,
    required this.secondaryLabelFontSize,
    required this.secondaryLabelOpacity,
  });

  final double height;
  final double horizontalPadding;
  final double contentGap;
  final double labelFontSize;
  final FontWeight labelFontWeight;
  final double secondaryLabelFontSize;
  final double secondaryLabelOpacity;

  factory TilawaFooterBarTokens.defaults() {
    return const TilawaFooterBarTokens(
      height: 56,
      horizontalPadding: 16,
      contentGap: 12,
      labelFontSize: 16,
      labelFontWeight: FontWeight.bold,
      secondaryLabelFontSize: 12,
      secondaryLabelOpacity: 0.7,
    );
  }

  TilawaFooterBarTokens copyWith({
    double? height,
    double? horizontalPadding,
    double? contentGap,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? secondaryLabelFontSize,
    double? secondaryLabelOpacity,
  }) {
    return TilawaFooterBarTokens(
      height: height ?? this.height,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      contentGap: contentGap ?? this.contentGap,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      labelFontWeight: labelFontWeight ?? this.labelFontWeight,
      secondaryLabelFontSize:
          secondaryLabelFontSize ?? this.secondaryLabelFontSize,
      secondaryLabelOpacity:
          secondaryLabelOpacity ?? this.secondaryLabelOpacity,
    );
  }

  static TilawaFooterBarTokens lerp(
    TilawaFooterBarTokens a,
    TilawaFooterBarTokens b,
    double t,
  ) {
    return TilawaFooterBarTokens(
      height: lerpTokenDouble(a.height, b.height, t),
      horizontalPadding: lerpTokenDouble(
        a.horizontalPadding,
        b.horizontalPadding,
        t,
      ),
      contentGap: lerpTokenDouble(a.contentGap, b.contentGap, t),
      labelFontSize: lerpTokenDouble(a.labelFontSize, b.labelFontSize, t),
      labelFontWeight: t < 0.5 ? a.labelFontWeight : b.labelFontWeight,
      secondaryLabelFontSize: lerpTokenDouble(
        a.secondaryLabelFontSize,
        b.secondaryLabelFontSize,
        t,
      ),
      secondaryLabelOpacity: lerpTokenDouble(
        a.secondaryLabelOpacity,
        b.secondaryLabelOpacity,
        t,
      ),
    );
  }
}

@immutable
class TilawaMediaPlayerBarTokens {
  const TilawaMediaPlayerBarTokens({
    required this.contentPadding,
    required this.borderRadius,
    required this.artworkSize,
    required this.artworkRadius,
    required this.titleFontWeight,
    required this.subtitleOpacity,
    required this.infoGap,
    required this.artworkInfoGap,
    required this.infoControlsGap,
    required this.controlsGap,
    required this.controlButtonSize,
    required this.playPauseButtonSize,
    required this.defaultIconSize,
    required this.playPauseIconSize,
    required this.disabledControlOpacity,
    required this.shadowOpacity,
    required this.shellBackgroundColor,
    required this.progressTrackBackgroundColor,
    required this.artworkPlaceholderColor,
    required this.shellOutlineColor,
  });

  final EdgeInsetsGeometry contentPadding;
  final double borderRadius;
  final double artworkSize;
  final double artworkRadius;
  final FontWeight titleFontWeight;
  final double subtitleOpacity;
  final double infoGap;
  final double artworkInfoGap;
  final double infoControlsGap;
  final double controlsGap;
  final double controlButtonSize;
  final double playPauseButtonSize;
  final double defaultIconSize;
  final double playPauseIconSize;
  final double disabledControlOpacity;
  final double shadowOpacity;

  /// Bar surface behind controls (persistent chrome).
  final Color shellBackgroundColor;

  /// [LinearProgressIndicator.backgroundColor] for the slim track.
  final Color progressTrackBackgroundColor;

  /// Placeholder fill behind album art when no image is shown.
  final Color artworkPlaceholderColor;

  /// Hairline border around the bar ([TilawaDesignTokens.opacitySubtle] on [ColorScheme.outlineVariant]).
  final Color shellOutlineColor;

  factory TilawaMediaPlayerBarTokens.defaults() {
    return TilawaMediaPlayerBarTokens.fromColorScheme(
      ColorScheme.fromSeed(seedColor: AppColors.defaultPrimary),
    );
  }

  factory TilawaMediaPlayerBarTokens.fromColorScheme(ColorScheme colorScheme) {
    // fix: Accessibility — ≥48dp transport control hit targets
    const shellOutlineAlpha = 0.1;
    return TilawaMediaPlayerBarTokens(
      // Slightly tighter vertical padding so the bar fits [playerCollapsedHeight]
      // with progress strip + 48dp artwork row inside the mini-player SizedBox
      // (outer shell also adds horizontal margins and tiny vertical padding).
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 16,
      artworkSize: 48,
      artworkRadius: 12,
      titleFontWeight: FontWeight.w600,
      subtitleOpacity: 0.7,
      infoGap: 2,
      artworkInfoGap: 12,
      infoControlsGap: 8,
      controlsGap: 4,
      controlButtonSize: kTilawaMinInteractiveDimension,
      playPauseButtonSize: kTilawaMinInteractiveDimension,
      defaultIconSize: 24,
      playPauseIconSize: 16,
      disabledControlOpacity: 0.3,
      shadowOpacity: 0.1,
      shellBackgroundColor: colorScheme.surfaceContainerLow,
      progressTrackBackgroundColor: colorScheme.surfaceContainerHighest
          .withValues(alpha: shellOutlineAlpha),
      artworkPlaceholderColor: colorScheme.surfaceContainerHigh,
      shellOutlineColor: colorScheme.outlineVariant.withValues(
        alpha: shellOutlineAlpha,
      ),
    );
  }

  TilawaMediaPlayerBarTokens copyWith({
    EdgeInsetsGeometry? contentPadding,
    double? borderRadius,
    double? artworkSize,
    double? artworkRadius,
    FontWeight? titleFontWeight,
    double? subtitleOpacity,
    double? infoGap,
    double? artworkInfoGap,
    double? infoControlsGap,
    double? controlsGap,
    double? controlButtonSize,
    double? playPauseButtonSize,
    double? defaultIconSize,
    double? playPauseIconSize,
    double? disabledControlOpacity,
    double? shadowOpacity,
    Color? shellBackgroundColor,
    Color? progressTrackBackgroundColor,
    Color? artworkPlaceholderColor,
    Color? shellOutlineColor,
  }) {
    return TilawaMediaPlayerBarTokens(
      contentPadding: contentPadding ?? this.contentPadding,
      borderRadius: borderRadius ?? this.borderRadius,
      artworkSize: artworkSize ?? this.artworkSize,
      artworkRadius: artworkRadius ?? this.artworkRadius,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      subtitleOpacity: subtitleOpacity ?? this.subtitleOpacity,
      infoGap: infoGap ?? this.infoGap,
      artworkInfoGap: artworkInfoGap ?? this.artworkInfoGap,
      infoControlsGap: infoControlsGap ?? this.infoControlsGap,
      controlsGap: controlsGap ?? this.controlsGap,
      controlButtonSize: controlButtonSize ?? this.controlButtonSize,
      playPauseButtonSize: playPauseButtonSize ?? this.playPauseButtonSize,
      defaultIconSize: defaultIconSize ?? this.defaultIconSize,
      playPauseIconSize: playPauseIconSize ?? this.playPauseIconSize,
      disabledControlOpacity:
          disabledControlOpacity ?? this.disabledControlOpacity,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shellBackgroundColor: shellBackgroundColor ?? this.shellBackgroundColor,
      progressTrackBackgroundColor:
          progressTrackBackgroundColor ?? this.progressTrackBackgroundColor,
      artworkPlaceholderColor:
          artworkPlaceholderColor ?? this.artworkPlaceholderColor,
      shellOutlineColor: shellOutlineColor ?? this.shellOutlineColor,
    );
  }

  static TilawaMediaPlayerBarTokens lerp(
    TilawaMediaPlayerBarTokens a,
    TilawaMediaPlayerBarTokens b,
    double t,
  ) {
    return TilawaMediaPlayerBarTokens(
      contentPadding: EdgeInsetsGeometry.lerp(
        a.contentPadding,
        b.contentPadding,
        t,
      )!,
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      artworkSize: lerpTokenDouble(a.artworkSize, b.artworkSize, t),
      artworkRadius: lerpTokenDouble(a.artworkRadius, b.artworkRadius, t),
      titleFontWeight: FontWeight.lerp(
        a.titleFontWeight,
        b.titleFontWeight,
        t,
      )!,
      subtitleOpacity: lerpTokenDouble(a.subtitleOpacity, b.subtitleOpacity, t),
      infoGap: lerpTokenDouble(a.infoGap, b.infoGap, t),
      artworkInfoGap: lerpTokenDouble(a.artworkInfoGap, b.artworkInfoGap, t),
      infoControlsGap: lerpTokenDouble(a.infoControlsGap, b.infoControlsGap, t),
      controlsGap: lerpTokenDouble(a.controlsGap, b.controlsGap, t),
      controlButtonSize: lerpTokenDouble(
        a.controlButtonSize,
        b.controlButtonSize,
        t,
      ),
      playPauseButtonSize: lerpTokenDouble(
        a.playPauseButtonSize,
        b.playPauseButtonSize,
        t,
      ),
      defaultIconSize: lerpTokenDouble(a.defaultIconSize, b.defaultIconSize, t),
      playPauseIconSize: lerpTokenDouble(
        a.playPauseIconSize,
        b.playPauseIconSize,
        t,
      ),
      disabledControlOpacity: lerpTokenDouble(
        a.disabledControlOpacity,
        b.disabledControlOpacity,
        t,
      ),
      shadowOpacity: lerpTokenDouble(a.shadowOpacity, b.shadowOpacity, t),
      shellBackgroundColor: Color.lerp(
        a.shellBackgroundColor,
        b.shellBackgroundColor,
        t,
      )!,
      progressTrackBackgroundColor: Color.lerp(
        a.progressTrackBackgroundColor,
        b.progressTrackBackgroundColor,
        t,
      )!,
      artworkPlaceholderColor: Color.lerp(
        a.artworkPlaceholderColor,
        b.artworkPlaceholderColor,
        t,
      )!,
      shellOutlineColor: Color.lerp(
        a.shellOutlineColor,
        b.shellOutlineColor,
        t,
      )!,
    );
  }
}

@immutable
class TilawaAdaptiveShellTokens {
  const TilawaAdaptiveShellTokens({
    required this.phoneBottomNavBarBaseHeight,
    required this.bottomNavHorizontalMargin,
    required this.bottomNavVerticalMargin,
    required this.bottomNavIconOnlyVerticalMargin,
    required this.bottomNavInternalPadding,
    required this.bottomNavInnerRadius,
    required this.bottomNavBorderWidth,
    required this.bottomNavItemGap,
    required this.bottomNavBackgroundColor,
    required this.bottomNavShadowOpacity,
    required this.bottomNavShadowBlur,
    required this.bottomNavShadowOffset,
    required this.bottomNavOutlineColor,
    required this.sideRailRadius,
    required this.sideRailIndicatorColor,
    required this.sideRailBackgroundColor,
    required this.sideRailOutlineColor,
    required this.sideRailShadowOpacity,
    required this.sideRailShadowBlur,
    required this.sideRailShadowOffset,
    required this.navButtonMinHeight,
    required this.navButtonVerticalPadding,
    required this.navButtonGap,
    required this.navButtonIconSize,
    required this.navButtonSelectedCenterScale,
    required this.navButtonUnselectedScale,
    required this.navButtonSelectedBackgroundColor,
    required this.navButtonSelectedBackgroundOpacity,
    required this.navButtonSelectedCenterOpacity,
    required this.navButtonLabelFontSize,
    required this.navButtonSelectedLabelWeight,
    required this.navButtonUnselectedLabelWeight,
    required this.navButtonSplashColor,
    required this.navButtonHighlightColor,
    required this.navButtonSelectionContainerVerticalPadding,
    required this.navButtonIconOnlyMinHeight,
    required this.navButtonIconOnlyVerticalPadding,
    required this.navButtonIconOnlySelectionContainerVerticalPadding,
  });

  /// Reserved height for the phone bottom nav **row** at unit text scale.
  ///
  /// Hosts should prefer [phoneBottomNavLayoutHeight] with the current
  /// [TextScaler] so scroll padding tracks a11y text scaling.
  final double phoneBottomNavBarBaseHeight;

  /// Horizontal inset of the phone bar from the screen edges (0 = full
  /// width).
  final double bottomNavHorizontalMargin;
  final double bottomNavVerticalMargin;

  /// Top inset above the phone bar when it is **icon-only** (tighter strip).
  final double bottomNavIconOnlyVerticalMargin;
  final double bottomNavInternalPadding;

  /// Top corner radius of the phone bottom bar (bottom corners are square).
  ///
  /// Uses the same value as [bottomNavInnerRadius] so the outer shell and
  /// per-item tap targets share one corner radius.
  double get bottomNavRadius => bottomNavInnerRadius;

  final double bottomNavInnerRadius;
  final double bottomNavBorderWidth;
  final double bottomNavItemGap;

  /// Stable neutral elevated chrome for the phone bottom nav container.
  ///
  /// Light mode uses [Colors.white] so the floating bar reads as a clean chip on
  /// the cream scaffold. Dark mode lerps [AppColors.darkSurfaceContainerHighBase]
  /// toward [AppColors.darkBackground] so it stays separate from
  /// primary-harmonized [ColorScheme] tiers.
  final Color bottomNavBackgroundColor;

  /// Alpha for the soft shadow under the floating bottom nav (uses
  /// [ColorScheme.shadow]). Kept low so elevation reads without a hazy band.
  final double bottomNavShadowOpacity;

  /// Blur radius for the floating bottom nav shadow.
  final double bottomNavShadowBlur;

  /// Offset for the floating bottom nav shadow.
  final Offset bottomNavShadowOffset;

  /// [RoundedRectangleBorder.side] for the floating bottom nav ([TilawaDesignTokens.opacitySubtle] on [ColorScheme.outlineVariant]).
  final Color bottomNavOutlineColor;

  final double sideRailRadius;

  /// [NavigationRail.indicatorColor]: primary tint over [ColorScheme.surfaceContainerHigh].
  final Color sideRailIndicatorColor;

  /// Frosted rail panel fill ([ColorScheme.surface] at [TilawaDesignTokens.opacityGlass]).
  final Color sideRailBackgroundColor;

  /// Hairline border around the side rail panel.
  final Color sideRailOutlineColor;

  final double sideRailShadowOpacity;
  final double sideRailShadowBlur;
  final Offset sideRailShadowOffset;
  final double navButtonMinHeight;
  final double navButtonVerticalPadding;

  /// Vertical gap between each destination **icon** and **label** on the
  /// phone bottom navigation bar. Applied as padding under the icon; included
  /// in [phoneBottomNavLayoutHeight] so hosts reserve matching chrome height.
  final double navButtonGap;
  final double navButtonIconSize;
  final double navButtonSelectedCenterScale;
  final double navButtonUnselectedScale;
  final Color navButtonSelectedBackgroundColor;
  final double navButtonSelectedBackgroundOpacity;
  final double navButtonSelectedCenterOpacity;
  final double navButtonLabelFontSize;
  final FontWeight navButtonSelectedLabelWeight;
  final FontWeight navButtonUnselectedLabelWeight;

  /// [InkWell.splashColor] for shell nav destinations (bottom + rail).
  final Color navButtonSplashColor;

  /// [InkWell.highlightColor] for shell nav destinations.
  final Color navButtonHighlightColor;

  /// Vertical padding inside the phone nav item pill ([AnimatedContainer] in
  /// the shell). Included in [phoneBottomNavLayoutHeight] so reserved shell
  /// padding matches painted chrome.
  final double navButtonSelectionContainerVerticalPadding;

  /// Min height for each phone nav slot in **icon-only** mode (no labels).
  final double navButtonIconOnlyMinHeight;

  /// Outer vertical padding around the icon column in icon-only phone nav.
  final double navButtonIconOnlyVerticalPadding;

  /// Pill vertical padding in icon-only phone nav (tighter than labeled).
  final double navButtonIconOnlySelectionContainerVerticalPadding;

  /// Height of the phone bottom nav row for [textScaler] (icon column + one
  /// label line), floored at [navButtonMinHeight].
  ///
  /// Matches the phone bottom nav column (icon + gap + label line + pill
  /// padding) so [TilawaShellPadding] can clear the painted bar.
  double phoneBottomNavLayoutHeight(TextScaler textScaler) =>
      TilawaAdaptiveShellTokens._phoneBottomNavLayoutHeight(
        navButtonMinHeight: navButtonMinHeight,
        navButtonVerticalPadding: navButtonVerticalPadding,
        navButtonIconSize: navButtonIconSize,
        navButtonSelectedCenterScale: navButtonSelectedCenterScale,
        navButtonGap: navButtonGap,
        navButtonLabelFontSize: navButtonLabelFontSize,
        navButtonSelectionContainerVerticalPadding:
            navButtonSelectionContainerVerticalPadding,
        textScaler: textScaler,
      );

  /// Height of the phone bottom nav row in **icon-only** mode.
  ///
  /// Matches [_NavButton] when labels are hidden; use with
  /// [phoneBottomNavLayoutHeight] so scroll padding tracks the shorter bar.
  double phoneBottomNavIconOnlyLayoutHeight(TextScaler textScaler) =>
      TilawaAdaptiveShellTokens._phoneBottomNavIconOnlyLayoutHeight(
        navButtonIconOnlyMinHeight: navButtonIconOnlyMinHeight,
        navButtonIconOnlyVerticalPadding: navButtonIconOnlyVerticalPadding,
        navButtonIconOnlySelectionContainerVerticalPadding:
            navButtonIconOnlySelectionContainerVerticalPadding,
        navButtonIconSize: navButtonIconSize,
        navButtonSelectedCenterScale: navButtonSelectedCenterScale,
        textScaler: textScaler,
      );

  static double _phoneBottomNavIconOnlyLayoutHeight({
    required double navButtonIconOnlyMinHeight,
    required double navButtonIconOnlyVerticalPadding,
    required double navButtonIconOnlySelectionContainerVerticalPadding,
    required double navButtonIconSize,
    required double navButtonSelectedCenterScale,
    required TextScaler textScaler,
  }) {
    final double iconBlock =
        navButtonIconOnlyVerticalPadding * 2 +
        textScaler.scale(navButtonIconSize) * navButtonSelectedCenterScale;
    final double pillVerticalInset =
        2 * navButtonIconOnlySelectionContainerVerticalPadding;
    return math.max(
      textScaler.scale(navButtonIconOnlyMinHeight),
      iconBlock + pillVerticalInset,
    );
  }

  static double _phoneBottomNavLayoutHeight({
    required double navButtonMinHeight,
    required double navButtonVerticalPadding,
    required double navButtonIconSize,
    required double navButtonSelectedCenterScale,
    required double navButtonGap,
    required double navButtonLabelFontSize,
    required double navButtonSelectionContainerVerticalPadding,
    required TextScaler textScaler,
  }) {
    const double labelLineHeight = 1.15;
    final double labelBlock =
        textScaler.scale(navButtonLabelFontSize) * labelLineHeight;
    final double iconBlock =
        navButtonVerticalPadding * 2 +
        navButtonIconSize * navButtonSelectedCenterScale;
    final double pillVerticalInset =
        2 * navButtonSelectionContainerVerticalPadding;
    return math.max(
      navButtonMinHeight,
      iconBlock + navButtonGap + labelBlock + pillVerticalInset,
    );
  }

  factory TilawaAdaptiveShellTokens.defaults() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.defaultPrimary,
    );
    return TilawaAdaptiveShellTokens.fromColorScheme(colorScheme);
  }

  factory TilawaAdaptiveShellTokens.fromColorScheme(ColorScheme colorScheme) {
    // Color is derived here so every phone bottom nav follows the
    // active theme without per-screen overrides.
    final bottomNavBackgroundColor = _bottomNavBackgroundColor(colorScheme);
    final shellChromeOutline = _shellChromeOutlineColor(colorScheme);
    final bool lightChrome = colorScheme.brightness == Brightness.light;
    const double navButtonMinHeight = 54;
    const double navButtonVerticalPadding = 4;
    const double navButtonIconSize = 22;
    const double navButtonSelectedCenterScale = 1.1;
    const double navButtonGap = 8;
    const double navButtonLabelFontSize = 10;
    const double navButtonSelectionContainerVerticalPadding = 5;
    const double navButtonIconOnlyMinHeight = 40;
    const double navButtonIconOnlyVerticalPadding = 1;
    const double navButtonIconOnlySelectionContainerVerticalPadding = 2;
    const TextScaler unitTextScaler = TextScaler.linear(1);
    final double phoneBottomNavBarBaseHeight =
        TilawaAdaptiveShellTokens._phoneBottomNavLayoutHeight(
          navButtonMinHeight: navButtonMinHeight,
          navButtonVerticalPadding: navButtonVerticalPadding,
          navButtonIconSize: navButtonIconSize,
          navButtonSelectedCenterScale: navButtonSelectedCenterScale,
          navButtonGap: navButtonGap,
          navButtonLabelFontSize: navButtonLabelFontSize,
          navButtonSelectionContainerVerticalPadding:
              navButtonSelectionContainerVerticalPadding,
          textScaler: unitTextScaler,
        );
    return TilawaAdaptiveShellTokens(
      phoneBottomNavBarBaseHeight: phoneBottomNavBarBaseHeight,
      bottomNavHorizontalMargin: 0,
      bottomNavVerticalMargin: 4,
      bottomNavIconOnlyVerticalMargin: 2,
      bottomNavInternalPadding: 8,
      bottomNavInnerRadius: 24,
      bottomNavBorderWidth: 1,
      bottomNavItemGap: 4,
      bottomNavBackgroundColor: bottomNavBackgroundColor,
      // Soft elevation: tight blur + small downward offset so the bar lifts
      // slightly without a hazy band over scroll content.
      bottomNavShadowOpacity: lightChrome ? 0.09 : 0.055,
      bottomNavShadowBlur: lightChrome ? 14 : 10,
      bottomNavShadowOffset: Offset(0, lightChrome ? 4 : 2),
      bottomNavOutlineColor: _bottomNavOutlineColor(colorScheme),
      sideRailRadius: 16,
      sideRailIndicatorColor: _sideRailIndicatorColor(colorScheme),
      sideRailBackgroundColor: _sideRailBackgroundColor(colorScheme),
      sideRailOutlineColor: shellChromeOutline,
      sideRailShadowOpacity: 0.05,
      sideRailShadowBlur: 12,
      sideRailShadowOffset: Offset(2, 0),
      navButtonMinHeight: navButtonMinHeight,
      navButtonVerticalPadding: navButtonVerticalPadding,
      navButtonGap: navButtonGap,
      navButtonIconSize: navButtonIconSize,
      navButtonSelectedCenterScale: navButtonSelectedCenterScale,
      navButtonUnselectedScale: 0.95,
      navButtonSelectedBackgroundColor: _navButtonSelectedBackgroundColor(
        colorScheme,
        bottomNavBackgroundColor,
      ),
      navButtonSelectedBackgroundOpacity: 0.2,
      navButtonSelectedCenterOpacity: 0.25,
      navButtonLabelFontSize: navButtonLabelFontSize,
      navButtonSelectedLabelWeight: FontWeight.w700,
      navButtonUnselectedLabelWeight: FontWeight.w500,
      navButtonSplashColor: _navButtonSplashColor(colorScheme),
      navButtonHighlightColor: _navButtonHighlightColor(colorScheme),
      navButtonSelectionContainerVerticalPadding:
          navButtonSelectionContainerVerticalPadding,
      navButtonIconOnlyMinHeight: navButtonIconOnlyMinHeight,
      navButtonIconOnlyVerticalPadding: navButtonIconOnlyVerticalPadding,
      navButtonIconOnlySelectionContainerVerticalPadding:
          navButtonIconOnlySelectionContainerVerticalPadding,
    );
  }

  static Color _navButtonSplashColor(ColorScheme colorScheme) {
    return colorScheme.onSurface.withValues(alpha: 0.06);
  }

  static Color _navButtonHighlightColor(ColorScheme colorScheme) {
    return colorScheme.onSurface.withValues(alpha: 0.04);
  }

  /// Matches [TilawaDesignTokens.opacitySubtle] (0.1) on [ColorScheme.outlineVariant].
  static Color _shellChromeOutlineColor(ColorScheme colorScheme) {
    return colorScheme.outlineVariant.withValues(alpha: 0.1);
  }

  /// Slightly stronger than [_shellChromeOutlineColor] so the white floating
  /// bar edge stays legible on cream scaffolds without looking heavy.
  static Color _bottomNavOutlineColor(ColorScheme colorScheme) {
    final double alpha = colorScheme.brightness == Brightness.light
        ? 0.17
        : 0.12;
    return colorScheme.outlineVariant.withValues(alpha: alpha);
  }

  /// Matches [TilawaDesignTokens.opacityGlass] (0.8) on [ColorScheme.surface].
  static Color _sideRailBackgroundColor(ColorScheme colorScheme) {
    return colorScheme.surface.withValues(alpha: 0.8);
  }

  static Color _sideRailIndicatorColor(ColorScheme colorScheme) {
    return Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.14),
      colorScheme.surfaceContainerHigh,
    );
  }

  /// Light phone nav uses an opaque white bar so the floating pill reads
  /// clearly above cream or tinted scaffolds. Dark keeps a filled bar for
  /// contrast.
  static Color _bottomNavBackgroundColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return Colors.white;
    }
    return Color.lerp(
          AppColors.darkSurfaceContainerHighBase,
          AppColors.darkBackground,
          0.32,
        ) ??
        AppColors.darkSurfaceContainerHighBase;
  }

  static Color _navButtonSelectedBackgroundColor(
    ColorScheme colorScheme,
    Color bottomNavBackgroundColor,
  ) {
    final tintOpacity = colorScheme.brightness == Brightness.dark ? 0.12 : 0.10;
    final base = bottomNavBackgroundColor.a == 0
        ? colorScheme.surfaceContainerLow
        : bottomNavBackgroundColor;
    return Color.alphaBlend(
      colorScheme.primary.withValues(alpha: tintOpacity),
      base,
    );
  }

  TilawaAdaptiveShellTokens copyWith({
    double? phoneBottomNavBarBaseHeight,
    double? bottomNavHorizontalMargin,
    double? bottomNavVerticalMargin,
    double? bottomNavIconOnlyVerticalMargin,
    double? bottomNavInternalPadding,
    double? bottomNavInnerRadius,
    double? bottomNavBorderWidth,
    double? bottomNavItemGap,
    Color? bottomNavBackgroundColor,
    double? bottomNavShadowOpacity,
    double? bottomNavShadowBlur,
    Offset? bottomNavShadowOffset,
    Color? bottomNavOutlineColor,
    double? sideRailRadius,
    Color? sideRailIndicatorColor,
    Color? sideRailBackgroundColor,
    Color? sideRailOutlineColor,
    double? sideRailShadowOpacity,
    double? sideRailShadowBlur,
    Offset? sideRailShadowOffset,
    double? navButtonMinHeight,
    double? navButtonVerticalPadding,
    double? navButtonGap,
    double? navButtonIconSize,
    double? navButtonSelectedCenterScale,
    double? navButtonUnselectedScale,
    Color? navButtonSelectedBackgroundColor,
    double? navButtonSelectedBackgroundOpacity,
    double? navButtonSelectedCenterOpacity,
    double? navButtonLabelFontSize,
    FontWeight? navButtonSelectedLabelWeight,
    FontWeight? navButtonUnselectedLabelWeight,
    Color? navButtonSplashColor,
    Color? navButtonHighlightColor,
    double? navButtonSelectionContainerVerticalPadding,
    double? navButtonIconOnlyMinHeight,
    double? navButtonIconOnlyVerticalPadding,
    double? navButtonIconOnlySelectionContainerVerticalPadding,
  }) {
    return TilawaAdaptiveShellTokens(
      phoneBottomNavBarBaseHeight:
          phoneBottomNavBarBaseHeight ?? this.phoneBottomNavBarBaseHeight,
      bottomNavHorizontalMargin:
          bottomNavHorizontalMargin ?? this.bottomNavHorizontalMargin,
      bottomNavVerticalMargin:
          bottomNavVerticalMargin ?? this.bottomNavVerticalMargin,
      bottomNavIconOnlyVerticalMargin:
          bottomNavIconOnlyVerticalMargin ??
          this.bottomNavIconOnlyVerticalMargin,
      bottomNavInternalPadding:
          bottomNavInternalPadding ?? this.bottomNavInternalPadding,
      bottomNavInnerRadius: bottomNavInnerRadius ?? this.bottomNavInnerRadius,
      bottomNavBorderWidth: bottomNavBorderWidth ?? this.bottomNavBorderWidth,
      bottomNavItemGap: bottomNavItemGap ?? this.bottomNavItemGap,
      bottomNavBackgroundColor:
          bottomNavBackgroundColor ?? this.bottomNavBackgroundColor,
      bottomNavShadowOpacity:
          bottomNavShadowOpacity ?? this.bottomNavShadowOpacity,
      bottomNavShadowBlur: bottomNavShadowBlur ?? this.bottomNavShadowBlur,
      bottomNavShadowOffset:
          bottomNavShadowOffset ?? this.bottomNavShadowOffset,
      bottomNavOutlineColor:
          bottomNavOutlineColor ?? this.bottomNavOutlineColor,
      sideRailRadius: sideRailRadius ?? this.sideRailRadius,
      sideRailIndicatorColor:
          sideRailIndicatorColor ?? this.sideRailIndicatorColor,
      sideRailBackgroundColor:
          sideRailBackgroundColor ?? this.sideRailBackgroundColor,
      sideRailOutlineColor: sideRailOutlineColor ?? this.sideRailOutlineColor,
      sideRailShadowOpacity:
          sideRailShadowOpacity ?? this.sideRailShadowOpacity,
      sideRailShadowBlur: sideRailShadowBlur ?? this.sideRailShadowBlur,
      sideRailShadowOffset: sideRailShadowOffset ?? this.sideRailShadowOffset,
      navButtonMinHeight: navButtonMinHeight ?? this.navButtonMinHeight,
      navButtonVerticalPadding:
          navButtonVerticalPadding ?? this.navButtonVerticalPadding,
      navButtonGap: navButtonGap ?? this.navButtonGap,
      navButtonIconSize: navButtonIconSize ?? this.navButtonIconSize,
      navButtonSelectedCenterScale:
          navButtonSelectedCenterScale ?? this.navButtonSelectedCenterScale,
      navButtonUnselectedScale:
          navButtonUnselectedScale ?? this.navButtonUnselectedScale,
      navButtonSelectedBackgroundColor:
          navButtonSelectedBackgroundColor ??
          this.navButtonSelectedBackgroundColor,
      navButtonSelectedBackgroundOpacity:
          navButtonSelectedBackgroundOpacity ??
          this.navButtonSelectedBackgroundOpacity,
      navButtonSelectedCenterOpacity:
          navButtonSelectedCenterOpacity ?? this.navButtonSelectedCenterOpacity,
      navButtonLabelFontSize:
          navButtonLabelFontSize ?? this.navButtonLabelFontSize,
      navButtonSelectedLabelWeight:
          navButtonSelectedLabelWeight ?? this.navButtonSelectedLabelWeight,
      navButtonUnselectedLabelWeight:
          navButtonUnselectedLabelWeight ?? this.navButtonUnselectedLabelWeight,
      navButtonSplashColor: navButtonSplashColor ?? this.navButtonSplashColor,
      navButtonHighlightColor:
          navButtonHighlightColor ?? this.navButtonHighlightColor,
      navButtonSelectionContainerVerticalPadding:
          navButtonSelectionContainerVerticalPadding ??
          this.navButtonSelectionContainerVerticalPadding,
      navButtonIconOnlyMinHeight:
          navButtonIconOnlyMinHeight ?? this.navButtonIconOnlyMinHeight,
      navButtonIconOnlyVerticalPadding:
          navButtonIconOnlyVerticalPadding ??
          this.navButtonIconOnlyVerticalPadding,
      navButtonIconOnlySelectionContainerVerticalPadding:
          navButtonIconOnlySelectionContainerVerticalPadding ??
          this.navButtonIconOnlySelectionContainerVerticalPadding,
    );
  }

  static TilawaAdaptiveShellTokens lerp(
    TilawaAdaptiveShellTokens a,
    TilawaAdaptiveShellTokens b,
    double t,
  ) {
    return TilawaAdaptiveShellTokens(
      phoneBottomNavBarBaseHeight: lerpTokenDouble(
        a.phoneBottomNavBarBaseHeight,
        b.phoneBottomNavBarBaseHeight,
        t,
      ),
      bottomNavHorizontalMargin: lerpTokenDouble(
        a.bottomNavHorizontalMargin,
        b.bottomNavHorizontalMargin,
        t,
      ),
      bottomNavVerticalMargin: lerpTokenDouble(
        a.bottomNavVerticalMargin,
        b.bottomNavVerticalMargin,
        t,
      ),
      bottomNavIconOnlyVerticalMargin: lerpTokenDouble(
        a.bottomNavIconOnlyVerticalMargin,
        b.bottomNavIconOnlyVerticalMargin,
        t,
      ),
      bottomNavInternalPadding: lerpTokenDouble(
        a.bottomNavInternalPadding,
        b.bottomNavInternalPadding,
        t,
      ),
      bottomNavInnerRadius: lerpTokenDouble(
        a.bottomNavInnerRadius,
        b.bottomNavInnerRadius,
        t,
      ),
      bottomNavBorderWidth: lerpTokenDouble(
        a.bottomNavBorderWidth,
        b.bottomNavBorderWidth,
        t,
      ),
      bottomNavItemGap: lerpTokenDouble(
        a.bottomNavItemGap,
        b.bottomNavItemGap,
        t,
      ),
      bottomNavBackgroundColor: Color.lerp(
        a.bottomNavBackgroundColor,
        b.bottomNavBackgroundColor,
        t,
      )!,
      bottomNavShadowOpacity: lerpTokenDouble(
        a.bottomNavShadowOpacity,
        b.bottomNavShadowOpacity,
        t,
      ),
      bottomNavShadowBlur: lerpTokenDouble(
        a.bottomNavShadowBlur,
        b.bottomNavShadowBlur,
        t,
      ),
      bottomNavShadowOffset: Offset.lerp(
        a.bottomNavShadowOffset,
        b.bottomNavShadowOffset,
        t,
      )!,
      bottomNavOutlineColor: Color.lerp(
        a.bottomNavOutlineColor,
        b.bottomNavOutlineColor,
        t,
      )!,
      sideRailRadius: lerpTokenDouble(a.sideRailRadius, b.sideRailRadius, t),
      sideRailIndicatorColor: Color.lerp(
        a.sideRailIndicatorColor,
        b.sideRailIndicatorColor,
        t,
      )!,
      sideRailBackgroundColor: Color.lerp(
        a.sideRailBackgroundColor,
        b.sideRailBackgroundColor,
        t,
      )!,
      sideRailOutlineColor: Color.lerp(
        a.sideRailOutlineColor,
        b.sideRailOutlineColor,
        t,
      )!,
      sideRailShadowOpacity: lerpTokenDouble(
        a.sideRailShadowOpacity,
        b.sideRailShadowOpacity,
        t,
      ),
      sideRailShadowBlur: lerpTokenDouble(
        a.sideRailShadowBlur,
        b.sideRailShadowBlur,
        t,
      ),
      sideRailShadowOffset: Offset.lerp(
        a.sideRailShadowOffset,
        b.sideRailShadowOffset,
        t,
      )!,
      navButtonMinHeight: lerpTokenDouble(
        a.navButtonMinHeight,
        b.navButtonMinHeight,
        t,
      ),
      navButtonVerticalPadding: lerpTokenDouble(
        a.navButtonVerticalPadding,
        b.navButtonVerticalPadding,
        t,
      ),
      navButtonGap: lerpTokenDouble(a.navButtonGap, b.navButtonGap, t),
      navButtonIconSize: lerpTokenDouble(
        a.navButtonIconSize,
        b.navButtonIconSize,
        t,
      ),
      navButtonSelectedCenterScale: lerpTokenDouble(
        a.navButtonSelectedCenterScale,
        b.navButtonSelectedCenterScale,
        t,
      ),
      navButtonUnselectedScale: lerpTokenDouble(
        a.navButtonUnselectedScale,
        b.navButtonUnselectedScale,
        t,
      ),
      navButtonSelectedBackgroundColor: Color.lerp(
        a.navButtonSelectedBackgroundColor,
        b.navButtonSelectedBackgroundColor,
        t,
      )!,
      navButtonSelectedBackgroundOpacity: lerpTokenDouble(
        a.navButtonSelectedBackgroundOpacity,
        b.navButtonSelectedBackgroundOpacity,
        t,
      ),
      navButtonSelectedCenterOpacity: lerpTokenDouble(
        a.navButtonSelectedCenterOpacity,
        b.navButtonSelectedCenterOpacity,
        t,
      ),
      navButtonLabelFontSize: lerpTokenDouble(
        a.navButtonLabelFontSize,
        b.navButtonLabelFontSize,
        t,
      ),
      navButtonSelectedLabelWeight: FontWeight.lerp(
        a.navButtonSelectedLabelWeight,
        b.navButtonSelectedLabelWeight,
        t,
      )!,
      navButtonUnselectedLabelWeight: FontWeight.lerp(
        a.navButtonUnselectedLabelWeight,
        b.navButtonUnselectedLabelWeight,
        t,
      )!,
      navButtonSplashColor: Color.lerp(
        a.navButtonSplashColor,
        b.navButtonSplashColor,
        t,
      )!,
      navButtonHighlightColor: Color.lerp(
        a.navButtonHighlightColor,
        b.navButtonHighlightColor,
        t,
      )!,
      navButtonSelectionContainerVerticalPadding: lerpTokenDouble(
        a.navButtonSelectionContainerVerticalPadding,
        b.navButtonSelectionContainerVerticalPadding,
        t,
      ),
      navButtonIconOnlyMinHeight: lerpTokenDouble(
        a.navButtonIconOnlyMinHeight,
        b.navButtonIconOnlyMinHeight,
        t,
      ),
      navButtonIconOnlyVerticalPadding: lerpTokenDouble(
        a.navButtonIconOnlyVerticalPadding,
        b.navButtonIconOnlyVerticalPadding,
        t,
      ),
      navButtonIconOnlySelectionContainerVerticalPadding: lerpTokenDouble(
        a.navButtonIconOnlySelectionContainerVerticalPadding,
        b.navButtonIconOnlySelectionContainerVerticalPadding,
        t,
      ),
    );
  }
}

@immutable
class TilawaSettingsGroupTokens {
  const TilawaSettingsGroupTokens({
    required this.groupHeaderPadding,
    required this.groupBorderRadius,
    required this.groupShadowOpacity,
    required this.groupShadowBlur,
    required this.groupShadowOffset,
    required this.groupTitleFontSize,
    required this.groupTitleLetterSpacing,
    required this.tileContentPadding,
    required this.switchTileContentPadding,
    required this.tileIconPadding,
    required this.tileIconBorderRadius,
    required this.tileIconSize,
    required this.tileTitleFontSize,
    required this.tileSubtitleFontSize,
    required this.tileSubtitleOpacity,
    required this.tileSubtitleSpacing,
    required this.tileTrailingSize,
    required this.tileTrailingOpacity,
    required this.tileIconContainerOpacity,
    required this.tileDividerPadding,
    required this.tileDividerHeight,
    required this.tileDividerThickness,
    required this.tileDividerOpacity,
    required this.switchActiveTrackOpacity,
    required this.tileItemGap,
    required this.selectionTileSelectedBackgroundColor,
    required this.groupSurfaceColor,
    required this.groupContainerBorderColor,
    required this.selectionTileDividerColor,
    required this.switchActiveTrackColor,
    required this.switchActiveThumbColor,
  });

  final EdgeInsetsGeometry groupHeaderPadding;
  final double groupBorderRadius;
  final double groupShadowOpacity;
  final double groupShadowBlur;
  final Offset groupShadowOffset;
  final double groupTitleFontSize;
  final double groupTitleLetterSpacing;
  final EdgeInsetsGeometry tileContentPadding;
  final EdgeInsetsGeometry switchTileContentPadding;
  final EdgeInsetsGeometry tileIconPadding;
  final double tileIconBorderRadius;
  final double tileIconSize;
  final double tileTitleFontSize;
  final double tileSubtitleFontSize;
  final double tileSubtitleOpacity;
  final double tileSubtitleSpacing;
  final double tileTrailingSize;
  final double tileTrailingOpacity;
  final double tileIconContainerOpacity;
  final EdgeInsetsGeometry tileDividerPadding;
  final double tileDividerHeight;
  final double tileDividerThickness;
  final double tileDividerOpacity;
  final double switchActiveTrackOpacity;
  final double tileItemGap;

  /// Selected row fill for [TilawaSelectionTile] (transparent by default).
  final Color selectionTileSelectedBackgroundColor;

  /// Rounded panel fill behind settings rows ([TilawaSettingsGroup]).
  final Color groupSurfaceColor;

  /// Hairline border around the group panel (`outlineVariant` × `tileDividerOpacity` × 2).
  final Color groupContainerBorderColor;

  /// Divider under [TilawaSelectionTile] rows (`outlineVariant` × [tileDividerOpacity]).
  final Color selectionTileDividerColor;

  /// [Switch.adaptive] active track ([ColorScheme.primary] × [switchActiveTrackOpacity]).
  final Color switchActiveTrackColor;

  /// [Switch.adaptive] thumb when on.
  final Color switchActiveThumbColor;

  /// Default tokens for the settings group.
  ///
  /// Horizontal list insets stay on [tileContentPadding] /
  /// [switchTileContentPadding]; vertical is zero so row height is driven by
  /// [ListTile.minTileHeight] (44 dp, [kTilawaMinInteractiveDimension]) in the
  /// settings tile widgets.
  factory TilawaSettingsGroupTokens.defaults() {
    return TilawaSettingsGroupTokens.fromColorScheme(
      ColorScheme.fromSeed(seedColor: AppColors.defaultPrimary),
    );
  }

  factory TilawaSettingsGroupTokens.fromColorScheme(ColorScheme colorScheme) {
    const tileIconContainerOpacity = 0.1;
    const selectionTileSelectedBackgroundColor = Colors.transparent;
    const tileDividerOpacity = 0.05;
    final groupSurfaceColor = colorScheme.surfaceContainerLow;
    final groupContainerBorderColor = _groupContainerBorderColor(
      colorScheme,
      tileDividerOpacity,
    );
    final selectionTileDividerColor = colorScheme.outlineVariant.withValues(
      alpha: tileDividerOpacity,
    );
    const switchActiveTrackOpacity = 0.5;
    final switchActiveTrackColor = colorScheme.primary.withValues(
      alpha: switchActiveTrackOpacity,
    );
    final switchActiveThumbColor = colorScheme.primary;

    return TilawaSettingsGroupTokens(
      groupHeaderPadding: const EdgeInsetsDirectional.fromSTEB(
        12,
        16,
        16,
        8,
      ),
      groupBorderRadius: 20,
      groupShadowOpacity: 0.06,
      groupShadowBlur: 10,
      groupShadowOffset: const Offset(0, 4),
      groupTitleFontSize: 12.5,
      groupTitleLetterSpacing: 1.1,
      tileContentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      switchTileContentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 0,
      ),
      tileIconPadding: const EdgeInsets.all(6),
      tileIconBorderRadius: 10,
      tileIconSize: 20,
      tileTitleFontSize: 14.5,
      tileSubtitleFontSize: 12.5,
      tileSubtitleOpacity: 0.6,
      tileSubtitleSpacing: 4,
      tileTrailingSize: 14,
      tileTrailingOpacity: 0.45,
      tileIconContainerOpacity: tileIconContainerOpacity,
      tileDividerPadding: const EdgeInsetsDirectional.only(
        start: 48,
        end: 16,
      ),
      tileDividerHeight: 1,
      tileDividerThickness: 0.5,
      tileDividerOpacity: tileDividerOpacity,
      switchActiveTrackOpacity: 0.5,
      tileItemGap: 16,
      selectionTileSelectedBackgroundColor:
          selectionTileSelectedBackgroundColor,
      groupSurfaceColor: groupSurfaceColor,
      groupContainerBorderColor: groupContainerBorderColor,
      selectionTileDividerColor: selectionTileDividerColor,
      switchActiveTrackColor: switchActiveTrackColor,
      switchActiveThumbColor: switchActiveThumbColor,
    );
  }

  static Color _groupContainerBorderColor(
    ColorScheme colorScheme,
    double tileDividerOpacity,
  ) {
    return colorScheme.outlineVariant.withValues(alpha: tileDividerOpacity * 2);
  }

  TilawaSettingsGroupTokens copyWith({
    EdgeInsetsGeometry? groupHeaderPadding,
    double? groupBorderRadius,
    double? groupShadowOpacity,
    double? groupShadowBlur,
    Offset? groupShadowOffset,
    double? groupTitleFontSize,
    double? groupTitleLetterSpacing,
    EdgeInsetsGeometry? tileContentPadding,
    EdgeInsetsGeometry? switchTileContentPadding,
    EdgeInsetsGeometry? tileIconPadding,
    double? tileIconBorderRadius,
    double? tileIconSize,
    double? tileTitleFontSize,
    double? tileSubtitleFontSize,
    double? tileSubtitleOpacity,
    double? tileSubtitleSpacing,
    double? tileTrailingSize,
    double? tileTrailingOpacity,
    double? tileIconContainerOpacity,
    EdgeInsetsGeometry? tileDividerPadding,
    double? tileDividerHeight,
    double? tileDividerThickness,
    double? tileDividerOpacity,
    double? switchActiveTrackOpacity,
    double? tileItemGap,
    Color? selectionTileSelectedBackgroundColor,
    Color? groupSurfaceColor,
    Color? groupContainerBorderColor,
    Color? selectionTileDividerColor,
    Color? switchActiveTrackColor,
    Color? switchActiveThumbColor,
  }) {
    return TilawaSettingsGroupTokens(
      groupHeaderPadding: groupHeaderPadding ?? this.groupHeaderPadding,
      groupBorderRadius: groupBorderRadius ?? this.groupBorderRadius,
      groupShadowOpacity: groupShadowOpacity ?? this.groupShadowOpacity,
      groupShadowBlur: groupShadowBlur ?? this.groupShadowBlur,
      groupShadowOffset: groupShadowOffset ?? this.groupShadowOffset,
      groupTitleFontSize: groupTitleFontSize ?? this.groupTitleFontSize,
      groupTitleLetterSpacing:
          groupTitleLetterSpacing ?? this.groupTitleLetterSpacing,
      tileContentPadding: tileContentPadding ?? this.tileContentPadding,
      switchTileContentPadding:
          switchTileContentPadding ?? this.switchTileContentPadding,
      tileIconPadding: tileIconPadding ?? this.tileIconPadding,
      tileIconBorderRadius: tileIconBorderRadius ?? this.tileIconBorderRadius,
      tileIconSize: tileIconSize ?? this.tileIconSize,
      tileTitleFontSize: tileTitleFontSize ?? this.tileTitleFontSize,
      tileSubtitleFontSize: tileSubtitleFontSize ?? this.tileSubtitleFontSize,
      tileSubtitleOpacity: tileSubtitleOpacity ?? this.tileSubtitleOpacity,
      tileSubtitleSpacing: tileSubtitleSpacing ?? this.tileSubtitleSpacing,
      tileTrailingSize: tileTrailingSize ?? this.tileTrailingSize,
      tileTrailingOpacity: tileTrailingOpacity ?? this.tileTrailingOpacity,
      tileIconContainerOpacity:
          tileIconContainerOpacity ?? this.tileIconContainerOpacity,
      tileDividerPadding: tileDividerPadding ?? this.tileDividerPadding,
      tileDividerHeight: tileDividerHeight ?? this.tileDividerHeight,
      tileDividerThickness: tileDividerThickness ?? this.tileDividerThickness,
      tileDividerOpacity: tileDividerOpacity ?? this.tileDividerOpacity,
      switchActiveTrackOpacity:
          switchActiveTrackOpacity ?? this.switchActiveTrackOpacity,
      tileItemGap: tileItemGap ?? this.tileItemGap,
      selectionTileSelectedBackgroundColor:
          selectionTileSelectedBackgroundColor ??
          this.selectionTileSelectedBackgroundColor,
      groupSurfaceColor: groupSurfaceColor ?? this.groupSurfaceColor,
      groupContainerBorderColor:
          groupContainerBorderColor ?? this.groupContainerBorderColor,
      selectionTileDividerColor:
          selectionTileDividerColor ?? this.selectionTileDividerColor,
      switchActiveTrackColor:
          switchActiveTrackColor ?? this.switchActiveTrackColor,
      switchActiveThumbColor:
          switchActiveThumbColor ?? this.switchActiveThumbColor,
    );
  }

  static TilawaSettingsGroupTokens lerp(
    TilawaSettingsGroupTokens a,
    TilawaSettingsGroupTokens b,
    double t,
  ) {
    return TilawaSettingsGroupTokens(
      groupHeaderPadding: EdgeInsetsGeometry.lerp(
        a.groupHeaderPadding,
        b.groupHeaderPadding,
        t,
      )!,
      groupBorderRadius: lerpTokenDouble(
        a.groupBorderRadius,
        b.groupBorderRadius,
        t,
      ),
      groupShadowOpacity: lerpTokenDouble(
        a.groupShadowOpacity,
        b.groupShadowOpacity,
        t,
      ),
      groupShadowBlur: lerpTokenDouble(a.groupShadowBlur, b.groupShadowBlur, t),
      groupShadowOffset: Offset.lerp(
        a.groupShadowOffset,
        b.groupShadowOffset,
        t,
      )!,
      groupTitleFontSize: lerpTokenDouble(
        a.groupTitleFontSize,
        b.groupTitleFontSize,
        t,
      ),
      groupTitleLetterSpacing: lerpTokenDouble(
        a.groupTitleLetterSpacing,
        b.groupTitleLetterSpacing,
        t,
      ),
      tileContentPadding: EdgeInsetsGeometry.lerp(
        a.tileContentPadding,
        b.tileContentPadding,
        t,
      )!,
      switchTileContentPadding: EdgeInsetsGeometry.lerp(
        a.switchTileContentPadding,
        b.switchTileContentPadding,
        t,
      )!,
      tileIconPadding: EdgeInsetsGeometry.lerp(
        a.tileIconPadding,
        b.tileIconPadding,
        t,
      )!,
      tileIconBorderRadius: lerpTokenDouble(
        a.tileIconBorderRadius,
        b.tileIconBorderRadius,
        t,
      ),
      tileIconSize: lerpTokenDouble(a.tileIconSize, b.tileIconSize, t),
      tileTitleFontSize: lerpTokenDouble(
        a.tileTitleFontSize,
        b.tileTitleFontSize,
        t,
      ),
      tileSubtitleFontSize: lerpTokenDouble(
        a.tileSubtitleFontSize,
        b.tileSubtitleFontSize,
        t,
      ),
      tileSubtitleOpacity: lerpTokenDouble(
        a.tileSubtitleOpacity,
        b.tileSubtitleOpacity,
        t,
      ),
      tileSubtitleSpacing: lerpTokenDouble(
        a.tileSubtitleSpacing,
        b.tileSubtitleSpacing,
        t,
      ),
      tileTrailingSize: lerpTokenDouble(
        a.tileTrailingSize,
        b.tileTrailingSize,
        t,
      ),
      tileTrailingOpacity: lerpTokenDouble(
        a.tileTrailingOpacity,
        b.tileTrailingOpacity,
        t,
      ),
      tileIconContainerOpacity: lerpTokenDouble(
        a.tileIconContainerOpacity,
        b.tileIconContainerOpacity,
        t,
      ),
      tileDividerPadding: EdgeInsetsGeometry.lerp(
        a.tileDividerPadding,
        b.tileDividerPadding,
        t,
      )!,
      tileDividerHeight: lerpTokenDouble(
        a.tileDividerHeight,
        b.tileDividerHeight,
        t,
      ),
      tileDividerThickness: lerpTokenDouble(
        a.tileDividerThickness,
        b.tileDividerThickness,
        t,
      ),
      tileDividerOpacity: lerpTokenDouble(
        a.tileDividerOpacity,
        b.tileDividerOpacity,
        t,
      ),
      switchActiveTrackOpacity: lerpTokenDouble(
        a.switchActiveTrackOpacity,
        b.switchActiveTrackOpacity,
        t,
      ),
      tileItemGap: lerpTokenDouble(a.tileItemGap, b.tileItemGap, t),
      selectionTileSelectedBackgroundColor: Color.lerp(
        a.selectionTileSelectedBackgroundColor,
        b.selectionTileSelectedBackgroundColor,
        t,
      )!,
      groupSurfaceColor: Color.lerp(
        a.groupSurfaceColor,
        b.groupSurfaceColor,
        t,
      )!,
      groupContainerBorderColor: Color.lerp(
        a.groupContainerBorderColor,
        b.groupContainerBorderColor,
        t,
      )!,
      selectionTileDividerColor: Color.lerp(
        a.selectionTileDividerColor,
        b.selectionTileDividerColor,
        t,
      )!,
      switchActiveTrackColor: Color.lerp(
        a.switchActiveTrackColor,
        b.switchActiveTrackColor,
        t,
      )!,
      switchActiveThumbColor: Color.lerp(
        a.switchActiveThumbColor,
        b.switchActiveThumbColor,
        t,
      )!,
    );
  }
}

@immutable
class TilawaImmersiveComposerTokens {
  const TilawaImmersiveComposerTokens({
    required this.defaultAutoHideDuration,
    required this.transitionDuration,
    required this.backgroundBlurScale,
    required this.backgroundOverlayOpacity,
    required this.overlayBorderOpacity,
    required this.shortWindowHeightBreakpoint,
    required this.shortWindowPanelHeightFactor,
    required this.regularPanelHeightFactor,
    required this.shortWindowPreviewHeightFactor,
    required this.regularPreviewHeightFactor,
    required this.panelMinHeight,
    required this.previewMaxHeight,
    required this.headerButtonSize,
    required this.headerIconSizeOffset,
    required this.composerSurfaceColor,
    required this.overlayPanelTranslucentFillColor,
    required this.panelBorderColor,
    required this.topBarSubtitleColor,
    required this.headerIconButtonFillColor,
  });

  final Duration defaultAutoHideDuration;
  final Duration transitionDuration;
  final double backgroundBlurScale;
  final double backgroundOverlayOpacity;
  final double overlayBorderOpacity;
  final double shortWindowHeightBreakpoint;
  final double shortWindowPanelHeightFactor;
  final double regularPanelHeightFactor;
  final double shortWindowPreviewHeightFactor;
  final double regularPreviewHeightFactor;
  final double panelMinHeight;
  final double previewMaxHeight;
  final double headerButtonSize;
  final double headerIconSizeOffset;

  /// Full-bleed scaffold fill and opaque overlay panels ([ColorScheme.surface]).
  final Color composerSurfaceColor;

  /// Bottom/top overlay panel fill when blur is on ([composerSurfaceColor] at [backgroundOverlayOpacity]).
  final Color overlayPanelTranslucentFillColor;

  /// Border on overlay panels and top bar ([ColorScheme.outlineVariant] at [overlayBorderOpacity]).
  final Color panelBorderColor;

  /// Subtitle text on [_TopAppBar].
  final Color topBarSubtitleColor;

  /// Opaque circle behind header icon buttons (e.g. close).
  final Color headerIconButtonFillColor;

  factory TilawaImmersiveComposerTokens.defaults() {
    return TilawaImmersiveComposerTokens.fromColorScheme(
      ColorScheme.fromSeed(seedColor: AppColors.defaultPrimary),
    );
  }

  factory TilawaImmersiveComposerTokens.fromColorScheme(
    ColorScheme colorScheme,
  ) {
    const backgroundBlurScale = 0.9;
    const backgroundOverlayOpacity = 0.42;
    const overlayBorderOpacity = 0.1;
    final surface = colorScheme.surface;
    return TilawaImmersiveComposerTokens(
      defaultAutoHideDuration: const Duration(seconds: 3),
      transitionDuration: const Duration(milliseconds: 300),
      backgroundBlurScale: backgroundBlurScale,
      backgroundOverlayOpacity: backgroundOverlayOpacity,
      overlayBorderOpacity: overlayBorderOpacity,
      shortWindowHeightBreakpoint: 760,
      shortWindowPanelHeightFactor: 0.5,
      regularPanelHeightFactor: 0.44,
      shortWindowPreviewHeightFactor: 0.42,
      regularPreviewHeightFactor: 0.5,
      panelMinHeight: 220,
      previewMaxHeight: 460,
      headerButtonSize: kTilawaMinInteractiveDimension,
      headerIconSizeOffset: 2,
      composerSurfaceColor: surface,
      overlayPanelTranslucentFillColor: surface.withValues(
        alpha: backgroundOverlayOpacity,
      ),
      panelBorderColor: colorScheme.outlineVariant.withValues(
        alpha: overlayBorderOpacity,
      ),
      topBarSubtitleColor: colorScheme.onSurfaceVariant,
      headerIconButtonFillColor: colorScheme.surfaceContainerHighest,
    );
  }

  TilawaImmersiveComposerTokens copyWith({
    Duration? defaultAutoHideDuration,
    Duration? transitionDuration,
    double? backgroundBlurScale,
    double? backgroundOverlayOpacity,
    double? overlayBorderOpacity,
    double? shortWindowHeightBreakpoint,
    double? shortWindowPanelHeightFactor,
    double? regularPanelHeightFactor,
    double? shortWindowPreviewHeightFactor,
    double? regularPreviewHeightFactor,
    double? panelMinHeight,
    double? previewMaxHeight,
    double? headerButtonSize,
    double? headerIconSizeOffset,
    Color? composerSurfaceColor,
    Color? overlayPanelTranslucentFillColor,
    Color? panelBorderColor,
    Color? topBarSubtitleColor,
    Color? headerIconButtonFillColor,
  }) {
    return TilawaImmersiveComposerTokens(
      defaultAutoHideDuration:
          defaultAutoHideDuration ?? this.defaultAutoHideDuration,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      backgroundBlurScale: backgroundBlurScale ?? this.backgroundBlurScale,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      overlayBorderOpacity: overlayBorderOpacity ?? this.overlayBorderOpacity,
      shortWindowHeightBreakpoint:
          shortWindowHeightBreakpoint ?? this.shortWindowHeightBreakpoint,
      shortWindowPanelHeightFactor:
          shortWindowPanelHeightFactor ?? this.shortWindowPanelHeightFactor,
      regularPanelHeightFactor:
          regularPanelHeightFactor ?? this.regularPanelHeightFactor,
      shortWindowPreviewHeightFactor:
          shortWindowPreviewHeightFactor ?? this.shortWindowPreviewHeightFactor,
      regularPreviewHeightFactor:
          regularPreviewHeightFactor ?? this.regularPreviewHeightFactor,
      panelMinHeight: panelMinHeight ?? this.panelMinHeight,
      previewMaxHeight: previewMaxHeight ?? this.previewMaxHeight,
      headerButtonSize: headerButtonSize ?? this.headerButtonSize,
      headerIconSizeOffset: headerIconSizeOffset ?? this.headerIconSizeOffset,
      composerSurfaceColor: composerSurfaceColor ?? this.composerSurfaceColor,
      overlayPanelTranslucentFillColor:
          overlayPanelTranslucentFillColor ??
          this.overlayPanelTranslucentFillColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      topBarSubtitleColor: topBarSubtitleColor ?? this.topBarSubtitleColor,
      headerIconButtonFillColor:
          headerIconButtonFillColor ?? this.headerIconButtonFillColor,
    );
  }

  static TilawaImmersiveComposerTokens lerp(
    TilawaImmersiveComposerTokens a,
    TilawaImmersiveComposerTokens b,
    double t,
  ) {
    return TilawaImmersiveComposerTokens(
      defaultAutoHideDuration: t < 0.5
          ? a.defaultAutoHideDuration
          : b.defaultAutoHideDuration,
      transitionDuration: t < 0.5 ? a.transitionDuration : b.transitionDuration,
      backgroundBlurScale: lerpTokenDouble(
        a.backgroundBlurScale,
        b.backgroundBlurScale,
        t,
      ),
      backgroundOverlayOpacity: lerpTokenDouble(
        a.backgroundOverlayOpacity,
        b.backgroundOverlayOpacity,
        t,
      ),
      overlayBorderOpacity: lerpTokenDouble(
        a.overlayBorderOpacity,
        b.overlayBorderOpacity,
        t,
      ),
      shortWindowHeightBreakpoint: lerpTokenDouble(
        a.shortWindowHeightBreakpoint,
        b.shortWindowHeightBreakpoint,
        t,
      ),
      shortWindowPanelHeightFactor: lerpTokenDouble(
        a.shortWindowPanelHeightFactor,
        b.shortWindowPanelHeightFactor,
        t,
      ),
      regularPanelHeightFactor: lerpTokenDouble(
        a.regularPanelHeightFactor,
        b.regularPanelHeightFactor,
        t,
      ),
      shortWindowPreviewHeightFactor: lerpTokenDouble(
        a.shortWindowPreviewHeightFactor,
        b.shortWindowPreviewHeightFactor,
        t,
      ),
      regularPreviewHeightFactor: lerpTokenDouble(
        a.regularPreviewHeightFactor,
        b.regularPreviewHeightFactor,
        t,
      ),
      panelMinHeight: lerpTokenDouble(a.panelMinHeight, b.panelMinHeight, t),
      previewMaxHeight: lerpTokenDouble(
        a.previewMaxHeight,
        b.previewMaxHeight,
        t,
      ),
      headerButtonSize: lerpTokenDouble(
        a.headerButtonSize,
        b.headerButtonSize,
        t,
      ),
      headerIconSizeOffset: lerpTokenDouble(
        a.headerIconSizeOffset,
        b.headerIconSizeOffset,
        t,
      ),
      composerSurfaceColor: Color.lerp(
        a.composerSurfaceColor,
        b.composerSurfaceColor,
        t,
      )!,
      overlayPanelTranslucentFillColor: Color.lerp(
        a.overlayPanelTranslucentFillColor,
        b.overlayPanelTranslucentFillColor,
        t,
      )!,
      panelBorderColor: Color.lerp(a.panelBorderColor, b.panelBorderColor, t)!,
      topBarSubtitleColor: Color.lerp(
        a.topBarSubtitleColor,
        b.topBarSubtitleColor,
        t,
      )!,
      headerIconButtonFillColor: Color.lerp(
        a.headerIconButtonFillColor,
        b.headerIconButtonFillColor,
        t,
      )!,
    );
  }
}

/// Component tokens for [TilawaBottomSheetScaffold].
///
/// Default insets follow the kit spacing scale: **16 dp** horizontal,
/// **12 dp** body top, **24 dp** body bottom (Medium / Extra Large on
/// [TilawaDesignTokens]) for reading-oriented sheets—see **§14** in root
/// `DESIGN.md`.
@immutable
class TilawaBottomSheetScaffoldTokens {
  const TilawaBottomSheetScaffoldTokens({
    required this.topRadius,
    required this.headerPadding,
    required this.bodyPadding,
    required this.closeButtonSize,
  });

  final double topRadius;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry bodyPadding;
  final double closeButtonSize;

  factory TilawaBottomSheetScaffoldTokens.defaults() {
    return const TilawaBottomSheetScaffoldTokens(
      topRadius: 28,
      headerPadding: EdgeInsets.fromLTRB(16, 8, 12, 12),
      bodyPadding: EdgeInsets.fromLTRB(16, 12, 16, 24),
      closeButtonSize: 40,
    );
  }

  TilawaBottomSheetScaffoldTokens copyWith({
    double? topRadius,
    EdgeInsetsGeometry? headerPadding,
    EdgeInsetsGeometry? bodyPadding,
    double? closeButtonSize,
  }) {
    return TilawaBottomSheetScaffoldTokens(
      topRadius: topRadius ?? this.topRadius,
      headerPadding: headerPadding ?? this.headerPadding,
      bodyPadding: bodyPadding ?? this.bodyPadding,
      closeButtonSize: closeButtonSize ?? this.closeButtonSize,
    );
  }

  static TilawaBottomSheetScaffoldTokens lerp(
    TilawaBottomSheetScaffoldTokens a,
    TilawaBottomSheetScaffoldTokens b,
    double t,
  ) {
    return TilawaBottomSheetScaffoldTokens(
      topRadius: lerpTokenDouble(a.topRadius, b.topRadius, t),
      headerPadding: EdgeInsetsGeometry.lerp(
        a.headerPadding,
        b.headerPadding,
        t,
      )!,
      bodyPadding: EdgeInsetsGeometry.lerp(a.bodyPadding, b.bodyPadding, t)!,
      closeButtonSize: lerpTokenDouble(a.closeButtonSize, b.closeButtonSize, t),
    );
  }
}
