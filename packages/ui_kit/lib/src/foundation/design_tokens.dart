import 'package:flutter/material.dart';

import 'density.dart';

/// Design tokens for the Tilawa UI Kit to avoid magic numbers
/// and ensure consistency across components.
@immutable
class TilawaDesignTokens extends ThemeExtension<TilawaDesignTokens> {
  const TilawaDesignTokens({
    required this.density,
    required this.spaceTiny,
    required this.spaceExtraSmall,
    required this.spaceSmall,
    required this.spaceMedium,
    required this.spaceLarge,
    required this.spaceExtraLarge,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusExtraLarge,
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
    required this.cardCompactWidthThreshold,
    required this.cardCompactHeightThreshold,
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
  });

  /// The density mode for this token set.
  final TilawaDensity density;

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

  /// 8.0
  final double radiusSmall;

  /// 12.0
  final double radiusMedium;

  /// 16.0
  final double radiusLarge;

  /// 24.0
  final double radiusExtraLarge;

  /// 0.1 — generic faint tint alpha for surface fills, painter strokes,
  /// and tinted backgrounds. Do not use as the alpha for `BoxShadow.color`
  /// — pick [opacityShadow] or [opacityShadowStrong] instead, which are
  /// calibrated for visible depth on real-device DPIs.
  final double opacitySubtle;

  /// 0.18 — default alpha for `BoxShadow.color` on small/elevated surfaces
  /// (cards, chips, search fields). Calibrated to remain visible at ~400 ppi
  /// while staying soft enough not to look like a hard drop shadow.
  final double opacityShadow;

  /// 0.28 — alpha for `BoxShadow.color` on hero/floating surfaces (glass
  /// panels, floating bottom nav, raised app bars) where stronger depth
  /// is desired.
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

  /// 48.0
  final double iconSizeExtraLarge;

  /// 1.8 — relaxed line height for dense Arabic text.
  final double textHeightLoose;

  /// 200ms
  final Duration durationFast;

  /// 400ms
  final Duration durationMedium;

  /// 600ms
  final Duration durationSlow;

  /// 720 — max width for the Quran reader body.
  final double contentMaxWidthReader;

  /// 560 — max width for settings, dialogs, auth, and sheets.
  final double contentMaxWidthForm;

  /// 1200 — max width for share composers and galleries.
  final double contentMaxWidthMedia;

  /// 760 — max width for settings detail pages.
  final double contentMaxWidthSettings;

  /// 180 — width threshold for compact card layout.
  final double cardCompactWidthThreshold;

  /// 155 — height threshold for compact card layout.
  final double cardCompactHeightThreshold;

  /// 145 — height threshold for tight card layout.
  final double cardTightHeightThreshold;

  /// 80.0
  final double playerCollapsedHeight;

  /// 80.0
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

  /// Default values for light/dark theme.
  ///
  /// [density] controls spacing and sizing. In Phase 0, both [comfortable]
  /// and [compact] produce identical values. Future phases will implement
  /// compact-specific value scaling.
  factory TilawaDesignTokens.light({
    TilawaDensity density = TilawaDensity.comfortable,
  }) => TilawaDesignTokens._create(density: density);

  factory TilawaDesignTokens.dark({
    TilawaDensity density = TilawaDensity.comfortable,
  }) => TilawaDesignTokens._create(density: density);

  /// Internal constructor for creating tokens with the given density.
  ///
  /// Compact density tightens medium/large spacing and radii so phones
  /// (typically `TilawaWindowSize.compact`) make better use of vertical
  /// real-estate without making everything feel cramped. Tiny/extra-small
  /// spacing is shared across densities — reducing further would compromise
  /// hit-target margins.
  factory TilawaDesignTokens._create({required TilawaDensity density}) {
    final isCompact = density.isCompact;
    return TilawaDesignTokens(
      density: density,
      spaceTiny: 2.0,
      spaceExtraSmall: 4.0,
      spaceSmall: 8.0,
      spaceMedium: isCompact ? 10.0 : 12.0,
      spaceLarge: isCompact ? 14.0 : 16.0,
      spaceExtraLarge: isCompact ? 20.0 : 24.0,
      radiusSmall: 8.0,
      radiusMedium: 12.0,
      radiusLarge: isCompact ? 14.0 : 16.0,
      radiusExtraLarge: isCompact ? 20.0 : 24.0,
      opacitySubtle: 0.1,
      opacityShadow: 0.18,
      opacityShadowStrong: 0.28,
      opacityMedium: 0.3,
      opacityEmphasis: 0.7,
      opacityGlass: 0.8,
      blurGlass: 12.0,
      blurShadow: 16.0,
      shadowOffsetSmall: const Offset(0, 2),
      shadowOffsetMedium: const Offset(0, 4),
      borderWidthThin: 0.5,
      progressHeight: 3.0,
      iconSizeExtraSmall: 12.0,
      iconSizeSmall: 16.0,
      iconSizeMedium: 20.0,
      iconSizeLarge: 24.0,
      iconSizeLargePlus: 42.0,
      iconSizeExtraLarge: 48.0,
      textHeightLoose: 2.0,
      durationFast: const Duration(milliseconds: 200),
      durationMedium: const Duration(milliseconds: 400),
      durationSlow: const Duration(milliseconds: 600),
      contentMaxWidthReader: 720,
      contentMaxWidthForm: 560,
      contentMaxWidthMedia: 1200,
      contentMaxWidthSettings: 760,
      cardCompactWidthThreshold: 180.0,
      cardCompactHeightThreshold: 155.0,
      cardTightHeightThreshold: 145.0,
      playerCollapsedHeight: 76.0,
      playerDismissThreshold: 76.0,
      playerMaxDismissOffset: 200.0,
      playerVelocityThreshold: 500.0,
      playerDismissVelocityThreshold: 300.0,
      playerDragSensitivity: 1.5,
      playerProgressThreshold: 0.5,
      playerIgnorePointerThreshold: 0.4,
      playerAlphaScalingFactor: 2.5,
    );
  }

  @override
  TilawaDesignTokens copyWith({
    TilawaDensity? density,
    double? spaceTiny,
    double? spaceExtraSmall,
    double? spaceSmall,
    double? spaceMedium,
    double? spaceLarge,
    double? spaceExtraLarge,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusExtraLarge,
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
    double? cardCompactWidthThreshold,
    double? cardCompactHeightThreshold,
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
  }) {
    return TilawaDesignTokens(
      density: density ?? this.density,
      spaceTiny: spaceTiny ?? this.spaceTiny,
      spaceExtraSmall: spaceExtraSmall ?? this.spaceExtraSmall,
      spaceSmall: spaceSmall ?? this.spaceSmall,
      spaceMedium: spaceMedium ?? this.spaceMedium,
      spaceLarge: spaceLarge ?? this.spaceLarge,
      spaceExtraLarge: spaceExtraLarge ?? this.spaceExtraLarge,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      radiusExtraLarge: radiusExtraLarge ?? this.radiusExtraLarge,
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
      cardCompactWidthThreshold:
          cardCompactWidthThreshold ?? this.cardCompactWidthThreshold,
      cardCompactHeightThreshold:
          cardCompactHeightThreshold ?? this.cardCompactHeightThreshold,
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
    );
  }

  @override
  TilawaDesignTokens lerp(ThemeExtension<TilawaDesignTokens>? other, double t) {
    if (other is! TilawaDesignTokens) return this;
    // For lerp, preserve the density of 'this' token.
    // Density-based value interpolation is handled per-property.
    return TilawaDesignTokens(
      density: density,
      spaceTiny: lerpDouble(spaceTiny, other.spaceTiny, t)!,
      spaceExtraSmall: lerpDouble(spaceExtraSmall, other.spaceExtraSmall, t)!,
      spaceSmall: lerpDouble(spaceSmall, other.spaceSmall, t)!,
      spaceMedium: lerpDouble(spaceMedium, other.spaceMedium, t)!,
      spaceLarge: lerpDouble(spaceLarge, other.spaceLarge, t)!,
      spaceExtraLarge: lerpDouble(spaceExtraLarge, other.spaceExtraLarge, t)!,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      radiusExtraLarge: lerpDouble(
        radiusExtraLarge,
        other.radiusExtraLarge,
        t,
      )!,
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
      cardCompactWidthThreshold: lerpDouble(
        cardCompactWidthThreshold,
        other.cardCompactWidthThreshold,
        t,
      )!,
      cardCompactHeightThreshold: lerpDouble(
        cardCompactHeightThreshold,
        other.cardCompactHeightThreshold,
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

extension TilawaIconSizeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TilawaDesignTokens get tokens => theme.tokens;
  double get iconSizeExtraSmall => tokens.iconSizeExtraSmall;
  double get iconSizeSmall => tokens.iconSizeSmall;
  double get iconSizeMedium => tokens.iconSizeMedium;
  double get iconSizeLarge => tokens.iconSizeLarge;
  double get iconSizeExtraLarge => tokens.iconSizeExtraLarge;
}
