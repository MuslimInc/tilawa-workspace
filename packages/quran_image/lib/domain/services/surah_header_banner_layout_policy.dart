import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../core/constants/surah_header_constants.dart';

/// Contract for Surah header banner layout calculations.
abstract class SurahHeaderBannerLayoutPolicy {
  const SurahHeaderBannerLayoutPolicy();

  /// Calculates the Quran line slot height from the rendered page width.
  double lineHeightForPageWidth(double pageWidth);

  /// Calculates all render metrics required by the Surah header banner widget.
  SurahHeaderBannerLayoutMetrics calculate(SurahHeaderBannerLayoutInput input);
}

/// Immutable input values for a Surah header banner layout pass.
class SurahHeaderBannerLayoutInput extends Equatable {
  const SurahHeaderBannerLayoutInput({
    required this.pageWidth,
    required this.pageHeight,
    required this.lineHeight,
    required this.inkCenterYFraction,
  });

  /// Rendered page width.
  final double pageWidth;

  /// Rendered page height.
  final double pageHeight;

  /// Height of the Quran line slot containing the header.
  final double lineHeight;

  /// Vertical center fraction of the Surah-name ink within the line asset.
  final double inkCenterYFraction;

  @override
  List<Object?> get props => [
    pageWidth,
    pageHeight,
    lineHeight,
    inkCenterYFraction,
  ];
}

/// Calculated metrics consumed by the Surah header banner widget.
class SurahHeaderBannerLayoutMetrics extends Equatable {
  const SurahHeaderBannerLayoutMetrics({
    required this.bannerWidth,
    required this.bannerHeight,
    required this.horizontalPadding,
    required this.verticalOffset,
  });

  /// Rendered banner width.
  final double bannerWidth;

  /// Rendered banner height.
  final double bannerHeight;

  /// Symmetric horizontal padding needed to center the banner.
  final double horizontalPadding;

  /// Vertical translation needed to align the banner window to the header ink.
  final double verticalOffset;

  @override
  List<Object?> get props => [
    bannerWidth,
    bannerHeight,
    horizontalPadding,
    verticalOffset,
  ];
}

/// Ayah-calibrated implementation for Quran image Surah header banners.
class CalibratedSurahHeaderBannerLayoutPolicy
    implements SurahHeaderBannerLayoutPolicy {
  const CalibratedSurahHeaderBannerLayoutPolicy();

  @override
  double lineHeightForPageWidth(double pageWidth) {
    return pageWidth *
        SurahHeaderConstants.lineHeightReferencePixels /
        SurahHeaderConstants.lineHeightReferenceWidth;
  }

  @override
  SurahHeaderBannerLayoutMetrics calculate(SurahHeaderBannerLayoutInput input) {
    final double widthRatio = _widthRatio(input).clamp(
      SurahHeaderConstants.minWidthRatio,
      SurahHeaderConstants.maxWidthRatio,
    );
    final double bannerWidth = (input.pageWidth * widthRatio).roundToDouble();
    final double bannerHeight =
        (bannerWidth * SurahHeaderConstants.bannerHeightToWidthRatio)
            .roundToDouble();
    final double centeredTop = (input.lineHeight - bannerHeight) / 2;
    final double desiredTop =
        (input.lineHeight * input.inkCenterYFraction) -
        (bannerHeight * SurahHeaderConstants.targetInkCenterYFraction);

    return SurahHeaderBannerLayoutMetrics(
      bannerWidth: bannerWidth,
      bannerHeight: bannerHeight,
      horizontalPadding: (input.pageWidth - bannerWidth) / 2,
      verticalOffset: desiredTop - centeredTop,
    );
  }

  double _widthRatio(SurahHeaderBannerLayoutInput input) {
    final double shortSide = math.min(input.pageWidth, input.pageHeight);
    final double longSide = math.max(input.pageWidth, input.pageHeight);
    final double aspectRatio = longSide > 0 ? shortSide / longSide : 0;

    return SurahHeaderConstants.portraitWidthRatioBase +
        (SurahHeaderConstants.portraitWidthRatioAspectSlope * aspectRatio) +
        (SurahHeaderConstants.portraitWidthRatioViewportSlope *
            input.pageWidth);
  }
}
