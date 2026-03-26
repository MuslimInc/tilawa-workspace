import 'package:flutter/material.dart';

/// Design tokens for the Tilawa UI Kit to avoid magic numbers
/// and ensure consistency across components.
@immutable
class TilawaDesignTokens extends ThemeExtension<TilawaDesignTokens> {
  const TilawaDesignTokens({
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
  });

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

  /// Default values for light/dark theme
  factory TilawaDesignTokens.light() => const TilawaDesignTokens(
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
      );

  factory TilawaDesignTokens.dark() => TilawaDesignTokens.light();

  @override
  TilawaDesignTokens copyWith({
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
  }) {
    return TilawaDesignTokens(
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
    );
  }

  @override
  TilawaDesignTokens lerp(
    ThemeExtension<TilawaDesignTokens>? other,
    double t,
  ) {
    if (other is! TilawaDesignTokens) return this;
    return TilawaDesignTokens(
      spaceExtraSmall: lerpDouble(spaceExtraSmall, other.spaceExtraSmall, t)!,
      spaceSmall: lerpDouble(spaceSmall, other.spaceSmall, t)!,
      spaceMedium: lerpDouble(spaceMedium, other.spaceMedium, t)!,
      spaceLarge: lerpDouble(spaceLarge, other.spaceLarge, t)!,
      spaceExtraLarge: lerpDouble(spaceExtraLarge, other.spaceExtraLarge, t)!,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      radiusExtraLarge:
          lerpDouble(radiusExtraLarge, other.radiusExtraLarge, t)!,
      opacitySubtle: lerpDouble(opacitySubtle, other.opacitySubtle, t)!,
      opacityMedium: lerpDouble(opacityMedium, other.opacityMedium, t)!,
      opacityEmphasis: lerpDouble(opacityEmphasis, other.opacityEmphasis, t)!,
      opacityGlass: lerpDouble(opacityGlass, other.opacityGlass, t)!,
      blurGlass: lerpDouble(blurGlass, other.blurGlass, t)!,
      blurShadow: lerpDouble(blurShadow, other.blurShadow, t)!,
      shadowOffsetSmall: Offset.lerp(shadowOffsetSmall, other.shadowOffsetSmall, t)!,
      shadowOffsetMedium:
          Offset.lerp(shadowOffsetMedium, other.shadowOffsetMedium, t)!,
      borderWidthThin: lerpDouble(borderWidthThin, other.borderWidthThin, t)!,
      progressHeight: lerpDouble(progressHeight, other.progressHeight, t)!,
      iconSizeSmall: lerpDouble(iconSizeSmall, other.iconSizeSmall, t)!,
      iconSizeMedium: lerpDouble(iconSizeMedium, other.iconSizeMedium, t)!,
      iconSizeLarge: lerpDouble(iconSizeLarge, other.iconSizeLarge, t)!,
      durationFast: t < 0.5 ? durationFast : other.durationFast,
      durationMedium: t < 0.5 ? durationMedium : other.durationMedium,
      durationSlow: t < 0.5 ? durationSlow : other.durationSlow,
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
