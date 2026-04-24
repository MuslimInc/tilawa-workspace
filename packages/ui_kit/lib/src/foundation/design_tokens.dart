import 'package:flutter/material.dart';

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
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusExtraLarge,
    required this.opacitySubtle,
    required this.opacityMedium,
    required this.opacityEmphasis,
    required this.opacityGlass,
    required this.blurGlass,
    required this.blurShadow,
    required this.shadowOffsetSmall,
    required this.shadowOffsetMedium,
    required this.borderWidthThin,
    required this.progressHeight,
    required this.iconSizeSmall,
    required this.iconSizeMedium,
    required this.iconSizeLarge,
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

  /// 8.0
  final double radiusSmall;

  /// 12.0
  final double radiusMedium;

  /// 16.0
  final double radiusLarge;

  /// 24.0
  final double radiusExtraLarge;

  /// 0.1
  final double opacitySubtle;

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

  /// 16.0
  final double iconSizeSmall;

  /// 20.0
  final double iconSizeMedium;

  /// 24.0
  final double iconSizeLarge;

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

  /// 194 — height threshold for compact card layout.
  final double cardCompactHeightThreshold;

  /// 145 — height threshold for tight card layout.
  final double cardTightHeightThreshold;

  /// Default values for light/dark theme
  factory TilawaDesignTokens.light() => const TilawaDesignTokens(
    spaceTiny: 2.0,
    spaceExtraSmall: 4.0,
    spaceSmall: 8.0,
    spaceMedium: 12.0,
    spaceLarge: 16.0,
    spaceExtraLarge: 24.0,
    radiusSmall: 8.0,
    radiusMedium: 12.0,
    radiusLarge: 16.0,
    radiusExtraLarge: 24.0,
    opacitySubtle: 0.1,
    opacityMedium: 0.3,
    opacityEmphasis: 0.7,
    opacityGlass: 0.8,
    blurGlass: 12.0,
    blurShadow: 16.0,
    shadowOffsetSmall: Offset(0, 2),
    shadowOffsetMedium: Offset(0, 4),
    borderWidthThin: 0.5,
    progressHeight: 3.0,
    iconSizeSmall: 16.0,
    iconSizeMedium: 20.0,
    iconSizeLarge: 24.0,
    durationFast: Duration(milliseconds: 200),
    durationMedium: Duration(milliseconds: 400),
    durationSlow: Duration(milliseconds: 600),
    contentMaxWidthReader: 720,
    contentMaxWidthForm: 560,
    contentMaxWidthMedia: 1200,
    contentMaxWidthSettings: 760,
    cardCompactWidthThreshold: 180.0,
    cardCompactHeightThreshold: 194.0,
    cardTightHeightThreshold: 145.0,
  );

  factory TilawaDesignTokens.dark() => TilawaDesignTokens.light();

  @override
  TilawaDesignTokens copyWith({
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
    double? opacityMedium,
    double? opacityEmphasis,
    double? opacityGlass,
    double? blurGlass,
    double? blurShadow,
    Offset? shadowOffsetSmall,
    Offset? shadowOffsetMedium,
    double? borderWidthThin,
    double? progressHeight,
    double? iconSizeSmall,
    double? iconSizeMedium,
    double? iconSizeLarge,
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
  }) {
    return TilawaDesignTokens(
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
      opacityMedium: opacityMedium ?? this.opacityMedium,
      opacityEmphasis: opacityEmphasis ?? this.opacityEmphasis,
      opacityGlass: opacityGlass ?? this.opacityGlass,
      blurGlass: blurGlass ?? this.blurGlass,
      blurShadow: blurShadow ?? this.blurShadow,
      shadowOffsetSmall: shadowOffsetSmall ?? this.shadowOffsetSmall,
      shadowOffsetMedium: shadowOffsetMedium ?? this.shadowOffsetMedium,
      borderWidthThin: borderWidthThin ?? this.borderWidthThin,
      progressHeight: progressHeight ?? this.progressHeight,
      iconSizeSmall: iconSizeSmall ?? this.iconSizeSmall,
      iconSizeMedium: iconSizeMedium ?? this.iconSizeMedium,
      iconSizeLarge: iconSizeLarge ?? this.iconSizeLarge,
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
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      radiusExtraLarge: lerpDouble(
        radiusExtraLarge,
        other.radiusExtraLarge,
        t,
      )!,
      opacitySubtle: lerpDouble(opacitySubtle, other.opacitySubtle, t)!,
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
      iconSizeSmall: lerpDouble(iconSizeSmall, other.iconSizeSmall, t)!,
      iconSizeMedium: lerpDouble(iconSizeMedium, other.iconSizeMedium, t)!,
      iconSizeLarge: lerpDouble(iconSizeLarge, other.iconSizeLarge, t)!,
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
    );
  }

  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0) + ((b ?? 0) - (a ?? 0)) * t;
  }
}

/// Helper extension to access tokens easily
extension TilawaDesignTokensX on ThemeData {
  TilawaDesignTokens get tokens => extension<TilawaDesignTokens>()!;
}
