import 'package:flutter/material.dart';

/// Tilawa minimum interactive (hit-target) dimension, in logical pixels.
///
/// **48 dp** — matches Material's minimum touch target and WCAG 2.5.5
/// (Target Size) Level AAA for the recommended size.
/// Single source of truth for hit targets across the design system.
/// [TilawaDesignTokens.minInteractiveDimension] and
/// `context.minInteractiveDimension` always resolve to this constant;
///
/// Use this (or `context.minInteractiveDimension` /
/// `tokens.minInteractiveDimension`) instead of Flutter's
/// `kMinInteractiveDimension` for all in-product hit targets.
///
/// ## Companion rule: `HitTestBehavior.opaque`
///
/// Every `GestureDetector` in this kit that wraps a visible interactive
/// surface must declare `behavior: HitTestBehavior.opaque` so taps on
/// transparent padding inside the declared bounds still register. Bare
/// `GestureDetector`s without `behavior` are reserved for non-visible
/// regions only — pan handlers, pan-to-dismiss layers, and similar
/// edge-of-screen gesture surfaces. A grep-based contract test in
/// `test/foundation/kit_contracts_test.dart` enforces this by allow-listing
/// the current `GestureDetector` call sites; new sites need to either
/// declare `behavior: HitTestBehavior.opaque` and update the allow-list,
/// or use a Material primitive (`InkWell`, `IconButton`, `ListTile`)
/// which already provides the hit-slop and ripple.
const double kTilawaMinInteractiveDimension = 48.0;

/// Design tokens for the Tilawa UI Kit to avoid magic numbers
/// and ensure consistency across components.
@immutable
class TilawaDesignTokens extends ThemeExtension<TilawaDesignTokens> {
  const TilawaDesignTokens({
    required this.spaceTiny,
    required this.spaceExtraSmall,
    required this.spaceSmall,
    required this.spaceMedium,
    required this.spaceLarge,
    required this.spaceExtraLarge,
    required this.spaceSection,
    required this.spaceXXL,
    required this.spaceHuge,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusExtraLarge,
    required this.radiusHero,
    required this.opacitySubtle,
    required this.opacityShadow,
    required this.opacityShadowStrong,
    required this.opacityMedium,
    required this.opacityEmphasis,
    required this.opacityGlass,
    required this.blurGlass,
    required this.blurShadow,
    required this.shadowOffsetSmall,
    required this.shadowOffsetMedium,
    required this.borderWidthThin,
    required this.progressHeight,
    required this.iconSizeExtraSmall,
    required this.iconSizeSmall,
    required this.iconSizeMedium,
    required this.iconSizeLarge,
    required this.iconSizeLargePlus,
    required this.iconSizeExtraLarge,
    required this.textHeightLoose,
    required this.durationFast,
    required this.durationMedium,
    required this.durationSlow,
    required this.contentMaxWidthReader,
    required this.contentMaxWidthForm,
    required this.contentMaxWidthMedia,
    required this.contentMaxWidthSettings,
    required this.narrowCardWidthThreshold,
    required this.narrowCardHeightThreshold,
    required this.cardTightHeightThreshold,
    required this.playerCollapsedHeight,
    required this.playerDismissThreshold,
    required this.playerMaxDismissOffset,
    required this.playerVelocityThreshold,
    required this.playerDismissVelocityThreshold,
    required this.playerDragSensitivity,
    required this.playerProgressThreshold,
    required this.playerIgnorePointerThreshold,
    required this.playerAlphaScalingFactor,
    required this.stateLayerHover,
    required this.stateLayerPressed,
    required this.stateLayerFocused,
    required this.focusRingWidth,
    required this.dropdownMenuGap,
  });

  /// 2.0
  final double spaceTiny;

  /// 4.0
  final double spaceExtraSmall;

  /// 8.0
  final double spaceSmall;

  /// 12.0
  final double spaceMedium;

  /// 16.0
  final double spaceLarge;

  /// 24.0
  final double spaceExtraLarge;

  /// 20.0 — gap between a screen title and the first content block.
  final double spaceSection;

  /// 32.0 — inter-section gap (Noon/Amazon card-to-section breathing room).
  final double spaceXXL;

  /// 48.0 — hero section separator (top-of-screen hero to first content group).
  final double spaceHuge;

  /// Horizontal inset for thumb-reach and sticky bottom primary actions.
  ///
  /// Keeps CTAs centered with generous side margin on phones (pairs with
  /// [TilawaBottomActionInset] and [TilawaBottomActionArea]).
  double get bottomActionHorizontalInset => spaceHuge;

  /// 6.0
  final double radiusSmall;

  /// 8.0 — decorative chips, icon boxes, nested controls.
  final double radiusMedium;

  /// 20.0 — chrome tracks, search bars, nested fields.
  final double radiusLarge;

  /// 24.0 — content cards and pill affordances (Behance lifestyle).
  final double radiusExtraLarge;

  /// 28.0 — dashboard / hub summary groups only.
  final double radiusHero;

  /// 24.0 — content cards ([TilawaCard], featured panels).
  double get radiusCard => radiusExtraLarge;

  /// 24.0 — grouped settings panels ([TilawaSettingsGroupPanel]).
  double get radiusSection => radiusExtraLarge;

  /// Full pill radius for a control of [height] (`height / 2`).
  double radiusPill(double height) => height / 2;

  /// Circular radius for a square icon control of [size] (`size / 2`).
  double radiusIcon(double size) => size / 2;

  /// 0.1 — generic faint tint alpha for surface fills, painter strokes,
  /// and tinted backgrounds. Do not use as the alpha for `BoxShadow.color`
  /// — pick [opacityShadow] or [opacityShadowStrong] instead, which are
  /// calibrated for visible depth on real-device DPIs.
  final double opacitySubtle;

  /// 0.05 — default alpha for `BoxShadow.color` on raised cards and chips.
  /// Calibrated for a soft Moneyloop-style lift (wide blur, low opacity).
  final double opacityShadow;

  /// 0.08 — alpha for `BoxShadow.color` on floating chrome (nav, FAB-adjacent).
  final double opacityShadowStrong;

  /// 0.3
  final double opacityMedium;

  /// 0.7
  final double opacityEmphasis;

  /// 0.8
  final double opacityGlass;

  /// 12.0
  final double blurGlass;

  /// 16.0
  final double blurShadow;

  /// Offset(0, 2)
  final Offset shadowOffsetSmall;

  /// Offset(0, 4)
  final Offset shadowOffsetMedium;

  /// 0.5
  final double borderWidthThin;

  /// 3.0
  final double progressHeight;

  /// 12.0
  final double iconSizeExtraSmall;

  /// 16.0
  final double iconSizeSmall;

  /// 20.0
  final double iconSizeMedium;

  /// 24.0
  final double iconSizeLarge;

  /// 42.0
  final double iconSizeLargePlus;

  /// 44.0 — largest *glyph* size in the default ramp. Sits just below
  /// [kTilawaMinInteractiveDimension] (48 dp) so a top-of-ramp icon fits
  /// comfortably inside the minimum hit target with breathing room.
  /// Use [minInteractiveDimension] for layout limits on tappable chrome,
  /// not necessarily every decorative icon.
  final double iconSizeExtraLarge;

  /// Tilawa minimum interactive (hit-target) dimension — always
  /// [kTilawaMinInteractiveDimension]. Use this (or the top-level constant)
  /// for *all* in-product hit targets instead of Flutter's
  /// `kMinInteractiveDimension`.
  double get minInteractiveDimension => kTilawaMinInteractiveDimension;

  /// 2.0 — relaxed line height for dense Arabic text.
  final double textHeightLoose;

  /// 200ms
  final Duration durationFast;

  /// 400ms
  final Duration durationMedium;

  /// 600ms
  final Duration durationSlow;

  /// Horizontal inset from the screen edge to toolbar leading/actions.
  double get appBarEdgePadding => spaceMedium;

  /// Trailing inset for [AppBar.actions] (pairs with [appBarEdgePadding] on leading).
  EdgeInsetsDirectional get appBarActionsPadding =>
      EdgeInsetsDirectional.only(end: appBarEdgePadding);

  /// 720 — max width for the Quran reader body.
  final double contentMaxWidthReader;

  /// 560 — max width for settings, dialogs, auth, and sheets.
  final double contentMaxWidthForm;

  /// 1200 — max width for share composers and galleries.
  final double contentMaxWidthMedia;

  /// 760 — max width for settings detail pages.
  final double contentMaxWidthSettings;

  /// 180 — width threshold for narrow (space-constrained) card layout.
  final double narrowCardWidthThreshold;

  /// 155 — height threshold for narrow (space-constrained) card layout.
  final double narrowCardHeightThreshold;

  /// 145 — height threshold for tight card layout.
  final double cardTightHeightThreshold;

  /// 57.0 — collapsed mini-player chrome height (matches [_create]).
  final double playerCollapsedHeight;

  /// 57.0 — dismiss gesture threshold aligned with [playerCollapsedHeight].
  final double playerDismissThreshold;

  /// 200.0
  final double playerMaxDismissOffset;

  /// 500.0
  final double playerVelocityThreshold;

  /// 300.0
  final double playerDismissVelocityThreshold;

  /// 1.5
  final double playerDragSensitivity;

  /// 0.5
  final double playerProgressThreshold;

  /// 0.4
  final double playerIgnorePointerThreshold;

  /// 2.5
  final double playerAlphaScalingFactor;

  /// 0.08 — alpha for the Material state layer on hover. Reach for this
  /// (over Flutter's `hoverColor` default) so calibrated hover wash on
  /// neutral surfaces stays visible without becoming a lavender tint.
  final double stateLayerHover;

  /// 0.12 — alpha for the Material state layer on press/splash. Pairs
  /// with [stateLayerHover] and [stateLayerFocused] so light and dark
  /// surfaces share a tuned interaction language.
  final double stateLayerPressed;

  /// 0.12 — alpha for the Material state layer on keyboard focus.
  final double stateLayerFocused;

  /// 2.0 — width of the focus indicator ring (Material 3 default). Centralised
  /// here so component-level focus styling is consistent.
  final double focusRingWidth;

  /// 4.0 — vertical gap between a closed dropdown field and its menu panel.
  final double dropdownMenuGap;

  /// Default values for light/dark theme.
  factory TilawaDesignTokens.light() => TilawaDesignTokens._create();

  factory TilawaDesignTokens.dark() => TilawaDesignTokens._create();

  factory TilawaDesignTokens._create() {
    return TilawaDesignTokens(
      spaceTiny: 2.0,
      spaceExtraSmall: 4.0,
      spaceSmall: 8.0,
      spaceMedium: 12.0,
      spaceLarge: 16.0,
      spaceExtraLarge: 24.0,
      spaceSection: 20.0,
      spaceXXL: 32.0,
      spaceHuge: 48.0,
      radiusSmall: 8.0,
      radiusMedium: 12.0,
      radiusLarge: 20.0,
      radiusExtraLarge: 24.0,
      radiusHero: 28.0,
      opacitySubtle: 0.1,
      opacityShadow: 0.04,
      opacityShadowStrong: 0.08,
      opacityMedium: 0.3,
      opacityEmphasis: 0.7,
      opacityGlass: 0.8,
      blurGlass: 12.0,
      blurShadow: 8.0,
      shadowOffsetSmall: const Offset(0, 1),
      shadowOffsetMedium: const Offset(0, 2),
      borderWidthThin: 0.5,
      progressHeight: 3.0,
      iconSizeExtraSmall: 12.0,
      iconSizeSmall: 16.0,
      iconSizeMedium: 20.0,
      iconSizeLarge: 24.0,
      iconSizeLargePlus: 42.0,
      iconSizeExtraLarge: 44.0,
      textHeightLoose: 2.0,
      durationFast: const Duration(milliseconds: 200),
      durationMedium: const Duration(milliseconds: 400),
      durationSlow: const Duration(milliseconds: 600),
      contentMaxWidthReader: 720,
      contentMaxWidthForm: 560,
      contentMaxWidthMedia: 1200,
      contentMaxWidthSettings: 760,
      narrowCardWidthThreshold: 180.0,
      narrowCardHeightThreshold: 155.0,
      cardTightHeightThreshold: 145.0,
      playerCollapsedHeight: 57.0,
      playerDismissThreshold: 57.0,
      playerMaxDismissOffset: 200.0,
      playerVelocityThreshold: 500.0,
      playerDismissVelocityThreshold: 300.0,
      playerDragSensitivity: 1.65,
      playerProgressThreshold: 0.45,
      playerIgnorePointerThreshold: 0.4,
      playerAlphaScalingFactor: 2.5,
      stateLayerHover: 0.08,
      stateLayerPressed: 0.12,
      stateLayerFocused: 0.12,
      focusRingWidth: 2.0,
      dropdownMenuGap: 4.0,
    );
  }

  @override
  TilawaDesignTokens copyWith({
    double? spaceTiny,
    double? spaceExtraSmall,
    double? spaceSmall,
    double? spaceMedium,
    double? spaceLarge,
    double? spaceExtraLarge,
    double? spaceSection,
    double? spaceXXL,
    double? spaceHuge,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusExtraLarge,
    double? radiusHero,
    double? opacitySubtle,
    double? opacityShadow,
    double? opacityShadowStrong,
    double? opacityMedium,
    double? opacityEmphasis,
    double? opacityGlass,
    double? blurGlass,
    double? blurShadow,
    Offset? shadowOffsetSmall,
    Offset? shadowOffsetMedium,
    double? borderWidthThin,
    double? progressHeight,
    double? iconSizeExtraSmall,
    double? iconSizeSmall,
    double? iconSizeMedium,
    double? iconSizeLarge,
    double? iconSizeLargePlus,
    double? iconSizeExtraLarge,
    double? textHeightLoose,
    Duration? durationFast,
    Duration? durationMedium,
    Duration? durationSlow,
    double? contentMaxWidthReader,
    double? contentMaxWidthForm,
    double? contentMaxWidthMedia,
    double? contentMaxWidthSettings,
    double? narrowCardWidthThreshold,
    double? narrowCardHeightThreshold,
    double? cardTightHeightThreshold,
    double? playerCollapsedHeight,
    double? playerDismissThreshold,
    double? playerMaxDismissOffset,
    double? playerVelocityThreshold,
    double? playerDismissVelocityThreshold,
    double? playerDragSensitivity,
    double? playerProgressThreshold,
    double? playerIgnorePointerThreshold,
    double? playerAlphaScalingFactor,
    double? stateLayerHover,
    double? stateLayerPressed,
    double? stateLayerFocused,
    double? focusRingWidth,
    double? dropdownMenuGap,
  }) {
    return TilawaDesignTokens(
      spaceTiny: spaceTiny ?? this.spaceTiny,
      spaceExtraSmall: spaceExtraSmall ?? this.spaceExtraSmall,
      spaceSmall: spaceSmall ?? this.spaceSmall,
      spaceMedium: spaceMedium ?? this.spaceMedium,
      spaceLarge: spaceLarge ?? this.spaceLarge,
      spaceExtraLarge: spaceExtraLarge ?? this.spaceExtraLarge,
      spaceSection: spaceSection ?? this.spaceSection,
      spaceXXL: spaceXXL ?? this.spaceXXL,
      spaceHuge: spaceHuge ?? this.spaceHuge,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      radiusExtraLarge: radiusExtraLarge ?? this.radiusExtraLarge,
      radiusHero: radiusHero ?? this.radiusHero,
      opacitySubtle: opacitySubtle ?? this.opacitySubtle,
      opacityShadow: opacityShadow ?? this.opacityShadow,
      opacityShadowStrong: opacityShadowStrong ?? this.opacityShadowStrong,
      opacityMedium: opacityMedium ?? this.opacityMedium,
      opacityEmphasis: opacityEmphasis ?? this.opacityEmphasis,
      opacityGlass: opacityGlass ?? this.opacityGlass,
      blurGlass: blurGlass ?? this.blurGlass,
      blurShadow: blurShadow ?? this.blurShadow,
      shadowOffsetSmall: shadowOffsetSmall ?? this.shadowOffsetSmall,
      shadowOffsetMedium: shadowOffsetMedium ?? this.shadowOffsetMedium,
      borderWidthThin: borderWidthThin ?? this.borderWidthThin,
      progressHeight: progressHeight ?? this.progressHeight,
      iconSizeExtraSmall: iconSizeExtraSmall ?? this.iconSizeExtraSmall,
      iconSizeSmall: iconSizeSmall ?? this.iconSizeSmall,
      iconSizeMedium: iconSizeMedium ?? this.iconSizeMedium,
      iconSizeLarge: iconSizeLarge ?? this.iconSizeLarge,
      iconSizeLargePlus: iconSizeLargePlus ?? this.iconSizeLargePlus,
      iconSizeExtraLarge: iconSizeExtraLarge ?? this.iconSizeExtraLarge,
      textHeightLoose: textHeightLoose ?? this.textHeightLoose,
      durationFast: durationFast ?? this.durationFast,
      durationMedium: durationMedium ?? this.durationMedium,
      durationSlow: durationSlow ?? this.durationSlow,
      contentMaxWidthReader:
          contentMaxWidthReader ?? this.contentMaxWidthReader,
      contentMaxWidthForm: contentMaxWidthForm ?? this.contentMaxWidthForm,
      contentMaxWidthMedia: contentMaxWidthMedia ?? this.contentMaxWidthMedia,
      contentMaxWidthSettings:
          contentMaxWidthSettings ?? this.contentMaxWidthSettings,
      narrowCardWidthThreshold:
          narrowCardWidthThreshold ?? this.narrowCardWidthThreshold,
      narrowCardHeightThreshold:
          narrowCardHeightThreshold ?? this.narrowCardHeightThreshold,
      cardTightHeightThreshold:
          cardTightHeightThreshold ?? this.cardTightHeightThreshold,
      playerCollapsedHeight:
          playerCollapsedHeight ?? this.playerCollapsedHeight,
      playerDismissThreshold:
          playerDismissThreshold ?? this.playerDismissThreshold,
      playerMaxDismissOffset:
          playerMaxDismissOffset ?? this.playerMaxDismissOffset,
      playerVelocityThreshold:
          playerVelocityThreshold ?? this.playerVelocityThreshold,
      playerDismissVelocityThreshold:
          playerDismissVelocityThreshold ?? this.playerDismissVelocityThreshold,
      playerDragSensitivity:
          playerDragSensitivity ?? this.playerDragSensitivity,
      playerProgressThreshold:
          playerProgressThreshold ?? this.playerProgressThreshold,
      playerIgnorePointerThreshold:
          playerIgnorePointerThreshold ?? this.playerIgnorePointerThreshold,
      playerAlphaScalingFactor:
          playerAlphaScalingFactor ?? this.playerAlphaScalingFactor,
      stateLayerHover: stateLayerHover ?? this.stateLayerHover,
      stateLayerPressed: stateLayerPressed ?? this.stateLayerPressed,
      stateLayerFocused: stateLayerFocused ?? this.stateLayerFocused,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      dropdownMenuGap: dropdownMenuGap ?? this.dropdownMenuGap,
    );
  }

  @override
  TilawaDesignTokens lerp(ThemeExtension<TilawaDesignTokens>? other, double t) {
    if (other is! TilawaDesignTokens) return this;
    return TilawaDesignTokens(
      spaceTiny: lerpDouble(spaceTiny, other.spaceTiny, t)!,
      spaceExtraSmall: lerpDouble(spaceExtraSmall, other.spaceExtraSmall, t)!,
      spaceSmall: lerpDouble(spaceSmall, other.spaceSmall, t)!,
      spaceMedium: lerpDouble(spaceMedium, other.spaceMedium, t)!,
      spaceLarge: lerpDouble(spaceLarge, other.spaceLarge, t)!,
      spaceExtraLarge: lerpDouble(spaceExtraLarge, other.spaceExtraLarge, t)!,
      spaceSection: lerpDouble(spaceSection, other.spaceSection, t)!,
      spaceXXL: lerpDouble(spaceXXL, other.spaceXXL, t)!,
      spaceHuge: lerpDouble(spaceHuge, other.spaceHuge, t)!,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      radiusExtraLarge: lerpDouble(
        radiusExtraLarge,
        other.radiusExtraLarge,
        t,
      )!,
      radiusHero: lerpDouble(radiusHero, other.radiusHero, t)!,
      opacitySubtle: lerpDouble(opacitySubtle, other.opacitySubtle, t)!,
      opacityShadow: lerpDouble(opacityShadow, other.opacityShadow, t)!,
      opacityShadowStrong: lerpDouble(
        opacityShadowStrong,
        other.opacityShadowStrong,
        t,
      )!,
      opacityMedium: lerpDouble(opacityMedium, other.opacityMedium, t)!,
      opacityEmphasis: lerpDouble(opacityEmphasis, other.opacityEmphasis, t)!,
      opacityGlass: lerpDouble(opacityGlass, other.opacityGlass, t)!,
      blurGlass: lerpDouble(blurGlass, other.blurGlass, t)!,
      blurShadow: lerpDouble(blurShadow, other.blurShadow, t)!,
      shadowOffsetSmall: Offset.lerp(
        shadowOffsetSmall,
        other.shadowOffsetSmall,
        t,
      )!,
      shadowOffsetMedium: Offset.lerp(
        shadowOffsetMedium,
        other.shadowOffsetMedium,
        t,
      )!,
      borderWidthThin: lerpDouble(borderWidthThin, other.borderWidthThin, t)!,
      progressHeight: lerpDouble(progressHeight, other.progressHeight, t)!,
      iconSizeExtraSmall: lerpDouble(
        iconSizeExtraSmall,
        other.iconSizeExtraSmall,
        t,
      )!,
      iconSizeSmall: lerpDouble(iconSizeSmall, other.iconSizeSmall, t)!,
      iconSizeMedium: lerpDouble(iconSizeMedium, other.iconSizeMedium, t)!,
      iconSizeLarge: lerpDouble(iconSizeLarge, other.iconSizeLarge, t)!,
      iconSizeLargePlus: lerpDouble(
        iconSizeLargePlus,
        other.iconSizeLargePlus,
        t,
      )!,
      iconSizeExtraLarge: lerpDouble(
        iconSizeExtraLarge,
        other.iconSizeExtraLarge,
        t,
      )!,
      textHeightLoose: lerpDouble(textHeightLoose, other.textHeightLoose, t)!,
      durationFast: t < 0.5 ? durationFast : other.durationFast,
      durationMedium: t < 0.5 ? durationMedium : other.durationMedium,
      durationSlow: t < 0.5 ? durationSlow : other.durationSlow,
      contentMaxWidthReader: lerpDouble(
        contentMaxWidthReader,
        other.contentMaxWidthReader,
        t,
      )!,
      contentMaxWidthForm: lerpDouble(
        contentMaxWidthForm,
        other.contentMaxWidthForm,
        t,
      )!,
      contentMaxWidthMedia: lerpDouble(
        contentMaxWidthMedia,
        other.contentMaxWidthMedia,
        t,
      )!,
      contentMaxWidthSettings: lerpDouble(
        contentMaxWidthSettings,
        other.contentMaxWidthSettings,
        t,
      )!,
      narrowCardWidthThreshold: lerpDouble(
        narrowCardWidthThreshold,
        other.narrowCardWidthThreshold,
        t,
      )!,
      narrowCardHeightThreshold: lerpDouble(
        narrowCardHeightThreshold,
        other.narrowCardHeightThreshold,
        t,
      )!,
      cardTightHeightThreshold: lerpDouble(
        cardTightHeightThreshold,
        other.cardTightHeightThreshold,
        t,
      )!,
      playerCollapsedHeight: lerpDouble(
        playerCollapsedHeight,
        other.playerCollapsedHeight,
        t,
      )!,
      playerDismissThreshold: lerpDouble(
        playerDismissThreshold,
        other.playerDismissThreshold,
        t,
      )!,
      playerMaxDismissOffset: lerpDouble(
        playerMaxDismissOffset,
        other.playerMaxDismissOffset,
        t,
      )!,
      playerVelocityThreshold: lerpDouble(
        playerVelocityThreshold,
        other.playerVelocityThreshold,
        t,
      )!,
      playerDismissVelocityThreshold: lerpDouble(
        playerDismissVelocityThreshold,
        other.playerDismissVelocityThreshold,
        t,
      )!,
      playerDragSensitivity: lerpDouble(
        playerDragSensitivity,
        other.playerDragSensitivity,
        t,
      )!,
      playerProgressThreshold: lerpDouble(
        playerProgressThreshold,
        other.playerProgressThreshold,
        t,
      )!,
      playerIgnorePointerThreshold: lerpDouble(
        playerIgnorePointerThreshold,
        other.playerIgnorePointerThreshold,
        t,
      )!,
      playerAlphaScalingFactor: lerpDouble(
        playerAlphaScalingFactor,
        other.playerAlphaScalingFactor,
        t,
      )!,
      stateLayerHover: lerpDouble(stateLayerHover, other.stateLayerHover, t)!,
      stateLayerPressed: lerpDouble(
        stateLayerPressed,
        other.stateLayerPressed,
        t,
      )!,
      stateLayerFocused: lerpDouble(
        stateLayerFocused,
        other.stateLayerFocused,
        t,
      )!,
      focusRingWidth: lerpDouble(focusRingWidth, other.focusRingWidth, t)!,
      dropdownMenuGap: lerpDouble(
        dropdownMenuGap,
        other.dropdownMenuGap,
        t,
      )!,
    );
  }

  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0) + ((b ?? 0) - (a ?? 0)) * t;
  }
}

/// Helper extension to access tokens easily
extension TilawaDesignTokensX on ThemeData {
  TilawaDesignTokens get tokens =>
      extension<TilawaDesignTokens>() ?? TilawaDesignTokens.light();
}

extension TilawaSpaceX on BuildContext {
  double get spaceSection => Theme.of(this).tokens.spaceSection;
  double get spaceXXL => Theme.of(this).tokens.spaceXXL;
  double get spaceHuge => Theme.of(this).tokens.spaceHuge;
}

extension TilawaIconSizeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TilawaDesignTokens get tokens => theme.tokens;
  double get iconSizeExtraSmall => tokens.iconSizeExtraSmall;
  double get iconSizeSmall => tokens.iconSizeSmall;
  double get iconSizeMedium => tokens.iconSizeMedium;
  double get iconSizeLarge => tokens.iconSizeLarge;
  double get iconSizeLargePlus => tokens.iconSizeLargePlus;
  double get iconSizeExtraLarge => tokens.iconSizeExtraLarge;

  /// Tilawa minimum interactive (hit-target) dimension. Use this instead of
  /// Flutter's `kMinInteractiveDimension`.
  double get minInteractiveDimension => tokens.minInteractiveDimension;
}

/// Helpers for keeping nested rounded containers visually concentric.
///
/// **The rule:** an inner rounded element nested inside an outer rounded
/// container looks correct only when their curves stay parallel. That requires
/// `innerRadius = outerRadius - padding` (the padding between them).
///
/// Hardcoding inner radii silently drifts when token values change. Always
/// compute via [concentricInner] so the math stays correct.
extension TilawaConcentricRadiusX on TilawaDesignTokens {
  /// Returns the radius an inner element should use so its corners stay
  /// parallel to an outer container's corners.
  ///
  /// - [outerRadius] — the outer container's corner radius.
  /// - [padding] — the gap between outer and inner edges (the outer's inner
  ///   padding on the side that touches the inner element).
  ///
  /// Clamped to `0` if padding ≥ outer radius (degenerate case: inner element
  /// is too close to the edge for any rounding).
  double concentricInner({
    required double outerRadius,
    required double padding,
  }) {
    final double inner = outerRadius - padding;
    return inner < 0 ? 0 : inner;
  }
}

/// Brand-doc roles for rounded components. Each family maps to a fixed token
/// cap — use [TilawaRadiusResolverX.resolveRadius] instead of raw `radiusXxx`
/// literals so a future token change ripples cleanly.
///
/// See `docs/tilawa_brand.md` §5 (Rhythm and elevation).
enum TilawaRadiusFamily {
  /// Containers that hold content (`TilawaCard`, sheets, body cards).
  card,

  /// Tappable affordances (chips, buttons, search fields). Resolves to
  /// [TilawaDesignTokens.radiusPill] when [height] is provided.
  pill,

  /// Chrome strips nested inside cards — standard search bars, segmented
  /// tracks, nested text fields.
  chrome,

  /// Grouped settings panels ([TilawaSettingsGroupPanel]).
  section,

  /// Dashboard / hub navigation groups ([TilawaHubNavigationGroup]).
  hero,

  /// Decorative or hairline elements (status dots, icon rests in list rows).
  decorative,

  /// Standalone square icon controls ([TilawaIconActionButton]).
  icon,

  /// Standard compact chips.
  chip,

  /// Standard selection cards/chips (e.g. Gender option).
  selection,
}

/// Resolves a component's corner radius from its brand role.
///
/// Pill and icon families derive from layout (`height / 2`, `size / 2`).
/// Card, section, chrome, hero, and decorative map to fixed token caps.
extension TilawaRadiusResolverX on TilawaDesignTokens {
  /// Returns the corner radius for [family].
  ///
  /// When [height] is omitted, [TilawaRadiusFamily.pill] falls back to a
  /// 48 dp affordance pill (`minInteractiveDimension / 2`).
  double resolveRadius({
    required TilawaRadiusFamily family,
    double height = 0,
    double width = 0,
  }) {
    return switch (family) {
      TilawaRadiusFamily.card => radiusMedium,
      TilawaRadiusFamily.pill =>
        height > 0
            ? radiusPill(height)
            : radiusPill(kTilawaMinInteractiveDimension),
      TilawaRadiusFamily.chrome => radiusMedium,
      TilawaRadiusFamily.section => radiusMedium,
      TilawaRadiusFamily.hero => radiusLarge,
      TilawaRadiusFamily.decorative => radiusMedium,
      TilawaRadiusFamily.icon => radiusIcon(
        _resolvedIconDimension(width: width, height: height),
      ),
      TilawaRadiusFamily.chip => radiusSmall,
      TilawaRadiusFamily.selection => radiusMedium,
    };
  }

  /// Corner radius for tappable buttons at [height].
  ///
  /// All kit and Material buttons (primary, secondary, outline, danger) share
  /// this pill radius — only color semantics differ.
  double buttonBorderRadius({double height = kTilawaMinInteractiveDimension}) =>
      resolveRadius(family: TilawaRadiusFamily.pill, height: height);

  /// Standard [RoundedRectangleBorder] for buttons at [height].
  RoundedRectangleBorder buttonShape({
    double height = kTilawaMinInteractiveDimension,
  }) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(buttonBorderRadius(height: height)),
  );

  /// Baseline [ButtonStyle] for Material [FilledButton], [OutlinedButton],
  /// [ElevatedButton], and [TextButton].
  ///
  /// Applies the kit pill shape and 48×48 dp minimum touch target. Pass
  /// [base] from a [ThemeData] button theme to preserve Flex/M3 colors while
  /// overriding shape.
  ButtonStyle materialButtonStyle({
    ButtonStyle? base,
    double height = kTilawaMinInteractiveDimension,
  }) {
    return (base ?? const ButtonStyle()).copyWith(
      minimumSize: WidgetStatePropertyAll(
        Size(kTilawaMinInteractiveDimension, height),
      ),
      shape: WidgetStatePropertyAll(buttonShape(height: height)),
    );
  }

  double _resolvedIconDimension({
    required double width,
    required double height,
  }) {
    if (width > 0 && height > 0) {
      return width < height ? width : height;
    }
    if (width > 0) {
      return width;
    }
    if (height > 0) {
      return height;
    }
    return minInteractiveDimension;
  }
}

/// Track + segment radii for [TilawaSegmentedControl] and
/// [TilawaLanguageSwitcher].
extension TilawaSegmentedRadiusX on TilawaDesignTokens {
  /// Returns concentric outer/inner radii from segment [itemHeight] and track
  /// [containerPadding].
  ///
  /// Neutral segmented controls default to [TilawaRadiusFamily.chrome] on the
  /// track (brand-doc §5). Standalone primary controls (language switcher) pass
  /// [TilawaRadiusFamily.pill] so the track reads as one capsule.
  ({double containerRadius, double itemRadius}) resolveSegmentedControlRadii({
    required double itemHeight,
    required double containerPadding,
    TilawaRadiusFamily trackFamily = TilawaRadiusFamily.chrome,
  }) {
    final double trackHeight = itemHeight + containerPadding * 2;
    final double containerRadius = trackFamily == TilawaRadiusFamily.pill
        ? resolveRadius(family: TilawaRadiusFamily.pill, height: trackHeight)
        : resolveRadius(family: trackFamily);
    final double itemRadius = concentricInner(
      outerRadius: containerRadius,
      padding: containerPadding,
    );
    return (containerRadius: containerRadius, itemRadius: itemRadius);
  }
}
