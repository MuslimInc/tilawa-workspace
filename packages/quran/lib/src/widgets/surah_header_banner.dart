import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Renders the decorative Surah name header banner.
///
/// Banner width is computed using a linear regression model calibrated
/// against Figma measurements from the Ayah app across multiple devices.
/// Height follows the intrinsic aspect ratio of the banner image asset.
class SurahHeaderBanner extends StatelessWidget {
  const SurahHeaderBanner({
    super.key,
    required this.surahNumber,
    required this.lineHeight,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.isLandscape,
    this.headerImageFilter,
    this.headerTextColor,
    this.headerFontSizeMultiplier = 0.45,
  });

  final int surahNumber;
  final double lineHeight;
  final double viewportWidth;
  final double viewportHeight;
  final bool isLandscape;
  final ColorFilter? headerImageFilter;
  final Color? headerTextColor;
  final double headerFontSizeMultiplier;

  static const AssetImage _bannerImage = AssetImage('assets/mainframe.png');
  static const double _bannerHeightToWidthRatio = 0.11228293967474158;
  static const double _portraitWidthRatioBase = 0.97354259;
  static const double _portraitWidthRatioAspectSlope = -0.015786;
  static const double _portraitWidthRatioViewportSlope = -0.0000049331266667;
  static const double _landscapeWidthRatioBase = 0.31947917;
  static const double _landscapeWidthRatioAspectSlope = 1.05269164;
  static const double _landscapeWidthRatioViewportSlope = 0.00001533733;
  static const double _titleVerticalOffsetRatio = -0.02;

  @override
  Widget build(BuildContext context) {
    final double bannerWidth = computeBannerWidth(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      isLandscape: isLandscape,
    );
    final double horizontalPadding = computeHorizontalPadding(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      isLandscape: isLandscape,
    );
    final double bannerHeight = computeBannerHeight(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      isLandscape: isLandscape,
    );
    final double headerFontSize = bannerHeight * headerFontSizeMultiplier;
    final double verticalOffset = bannerHeight * _titleVerticalOffsetRatio;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SizedBox(
        height: bannerHeight,
        width: bannerWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image(
                image: _bannerImage,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.low,
                color: headerImageFilter == null ? null : Colors.white,
                colorBlendMode: headerImageFilter == null
                    ? null
                    : BlendMode.modulate,
              ),
            ),
            // The Surah name calligraphy from QCF_BSML font.
            Transform.translate(
              offset: Offset(0, verticalOffset),
              child: Text(
                String.fromCharCode(0xF100 + surahNumber - 1),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'QCF_BSML',
                  package: 'quran',
                  fontSize: headerFontSize,
                  color:
                      headerTextColor ??
                      Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @visibleForTesting
  static double computeBannerHeight({
    required double viewportWidth,
    required double viewportHeight,
    required bool isLandscape,
  }) {
    return (computeBannerWidth(
              viewportWidth: viewportWidth,
              viewportHeight: viewportHeight,
              isLandscape: isLandscape,
            ) *
            _bannerHeightToWidthRatio)
        .roundToDouble();
  }

  @visibleForTesting
  static double computeBannerWidth({
    required double viewportWidth,
    required double viewportHeight,
    required bool isLandscape,
  }) {
    final double normalizedAspectRatio = _normalizedAspectRatio(
      viewportWidth,
      viewportHeight,
    );
    final double widthRatio = isLandscape
        ? _computeLandscapeWidthRatio(
            viewportWidth: viewportWidth,
            normalizedAspectRatio: normalizedAspectRatio,
          )
        : _computePortraitWidthRatio(
            viewportWidth: viewportWidth,
            normalizedAspectRatio: normalizedAspectRatio,
          );

    return (viewportWidth * widthRatio.clamp(0.0, 1.0)).roundToDouble();
  }

  static double _computePortraitWidthRatio({
    required double viewportWidth,
    required double normalizedAspectRatio,
  }) {
    return _portraitWidthRatioBase +
        (_portraitWidthRatioAspectSlope * normalizedAspectRatio) +
        (_portraitWidthRatioViewportSlope * viewportWidth);
  }

  static double _computeLandscapeWidthRatio({
    required double viewportWidth,
    required double normalizedAspectRatio,
  }) {
    return _landscapeWidthRatioBase +
        (_landscapeWidthRatioAspectSlope * normalizedAspectRatio) +
        (_landscapeWidthRatioViewportSlope * viewportWidth);
  }

  @visibleForTesting
  static double computeHorizontalPadding({
    required double viewportWidth,
    required double viewportHeight,
    required bool isLandscape,
  }) {
    final double bannerWidth = computeBannerWidth(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      isLandscape: isLandscape,
    );
    return (viewportWidth - bannerWidth) / 2;
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
