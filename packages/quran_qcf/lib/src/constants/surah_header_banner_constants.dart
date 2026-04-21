import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Centralized Surah header banner calibration and asset tokens.
class SurahHeaderBannerConstants {
  SurahHeaderBannerConstants._();

  static const String assetPath = 'assets/sura_header_banner.png';
  static const String packageName = 'quran';
  static const AssetImage assetImage = AssetImage(
    assetPath,
    package: packageName,
  );

  static const String fontFamily = 'QCF_BSML';
  static const int glyphBaseCodePoint = 0xF100;

  static const double defaultFontSizeMultiplier = 0.45;
  static const double heightToWidthRatio = 0.11228293967474158;
  static const double titleVerticalOffsetRatio = -0.02;

  static const double minimumWidthRatio = 0.0;
  static const double maximumWidthRatio = 1.0;

  static const SurahHeaderBannerWidthCoefficients portraitWidthCoefficients =
      SurahHeaderBannerWidthCoefficients(
        base: 0.97354259,
        aspectSlope: -0.015786,
        viewportSlope: -0.0000049331266667,
      );

  static const SurahHeaderBannerWidthCoefficients landscapeWidthCoefficients =
      SurahHeaderBannerWidthCoefficients(
        base: 0.31947917,
        aspectSlope: 1.05269164,
        viewportSlope: 0.00001533733,
      );
}

@immutable
class SurahHeaderBannerWidthCoefficients {
  const SurahHeaderBannerWidthCoefficients({
    required this.base,
    required this.aspectSlope,
    required this.viewportSlope,
  });

  final double base;
  final double aspectSlope;
  final double viewportSlope;

  double widthRatio({
    required double viewportWidth,
    required double normalizedAspectRatio,
  }) {
    return base +
        (aspectSlope * normalizedAspectRatio) +
        (viewportSlope * viewportWidth);
  }
}
