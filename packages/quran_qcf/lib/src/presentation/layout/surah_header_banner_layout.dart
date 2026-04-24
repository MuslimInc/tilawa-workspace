import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/surah_header_banner_constants.dart';

/// Contract for Surah header banner layout calculation.
abstract class SurahHeaderBannerLayoutPolicy {
  const SurahHeaderBannerLayoutPolicy();

  SurahHeaderBannerLayoutMetrics calculate(SurahHeaderBannerLayoutInput input);
}

@immutable
class SurahHeaderBannerLayoutInput extends Equatable {
  const SurahHeaderBannerLayoutInput({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.isLandscape,
    required this.fontSizeMultiplier,
  });

  final double viewportWidth;
  final double viewportHeight;
  final bool isLandscape;
  final double fontSizeMultiplier;

  @override
  List<Object?> get props => [
    viewportWidth,
    viewportHeight,
    isLandscape,
    fontSizeMultiplier,
  ];
}

@immutable
class SurahHeaderBannerLayoutMetrics extends Equatable {
  const SurahHeaderBannerLayoutMetrics({
    required this.width,
    required this.height,
    required this.horizontalPadding,
    required this.fontSize,
    required this.titleVerticalOffset,
  });

  final double width;
  final double height;
  final double horizontalPadding;
  final double fontSize;
  final double titleVerticalOffset;

  @override
  List<Object?> get props => [
    width,
    height,
    horizontalPadding,
    fontSize,
    titleVerticalOffset,
  ];
}

/// Default Ayah-calibrated banner sizing policy.
class CalibratedSurahHeaderBannerLayoutPolicy
    implements SurahHeaderBannerLayoutPolicy {
  const CalibratedSurahHeaderBannerLayoutPolicy();

  @override
  SurahHeaderBannerLayoutMetrics calculate(SurahHeaderBannerLayoutInput input) {
    final double normalizedAspectRatio = _normalizedAspectRatio(
      input.viewportWidth,
      input.viewportHeight,
    );
    final SurahHeaderBannerWidthCoefficients coefficients = input.isLandscape
        ? SurahHeaderBannerConstants.landscapeWidthCoefficients
        : SurahHeaderBannerConstants.portraitWidthCoefficients;
    final double widthRatio = coefficients
        .widthRatio(
          viewportWidth: input.viewportWidth,
          normalizedAspectRatio: normalizedAspectRatio,
        )
        .clamp(
          SurahHeaderBannerConstants.minimumWidthRatio,
          SurahHeaderBannerConstants.maximumWidthRatio,
        );
    final double width = (input.viewportWidth * widthRatio).roundToDouble();
    final double height =
        (width * SurahHeaderBannerConstants.heightToWidthRatio).roundToDouble();

    return SurahHeaderBannerLayoutMetrics(
      width: width,
      height: height,
      horizontalPadding: (input.viewportWidth - width) / 2,
      fontSize: height * input.fontSizeMultiplier,
      titleVerticalOffset:
          height * SurahHeaderBannerConstants.titleVerticalOffsetRatio,
    );
  }

  static double _normalizedAspectRatio(
    double viewportWidth,
    double viewportHeight,
  ) {
    final double shortSide = math.min(viewportWidth, viewportHeight);
    final double longSide = math.max(viewportWidth, viewportHeight);
    if (longSide == 0) {
      return 0;
    }
    return shortSide / longSide;
  }
}
