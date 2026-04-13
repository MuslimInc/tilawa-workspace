import 'package:flutter/material.dart';

import '../constants/quran_constants.dart';
import '../constants/surah_header_banner_constants.dart';
import '../layout/surah_header_banner_layout.dart';
import 'surah_header_glyph_provider.dart';

/// Renders the decorative Surah name header banner.
///
/// Rendering is intentionally thin: sizing is delegated to
/// [SurahHeaderBannerLayoutPolicy] and glyph lookup is delegated to
/// [SurahHeaderGlyphProvider].
class SurahHeaderBanner extends StatelessWidget {
  const SurahHeaderBanner({
    super.key,
    required this.surahNumber,
    this.lineHeight = 0.0,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.isLandscape,
    this.headerImageFilter,
    this.headerTextColor,
    this.headerFontSizeMultiplier =
        SurahHeaderBannerConstants.defaultFontSizeMultiplier,
    this.layoutPolicy = const CalibratedSurahHeaderBannerLayoutPolicy(),
    this.glyphProvider = const QcfSurahHeaderGlyphProvider(),
  }) : assert(
         surahNumber >= QuranConstants.minSurahNumber &&
             surahNumber <= QuranConstants.maxSurahNumber,
       );

  final int surahNumber;

  /// Retained for source compatibility with older callers.
  ///
  /// Current banner sizing is viewport-calibrated and does not depend on line
  /// height.
  final double lineHeight;
  final double viewportWidth;
  final double viewportHeight;
  final bool isLandscape;
  final ColorFilter? headerImageFilter;
  final Color? headerTextColor;
  final double headerFontSizeMultiplier;
  final SurahHeaderBannerLayoutPolicy layoutPolicy;
  final SurahHeaderGlyphProvider glyphProvider;

  static const SurahHeaderBannerLayoutPolicy _defaultLayoutPolicy =
      CalibratedSurahHeaderBannerLayoutPolicy();

  @override
  Widget build(BuildContext context) {
    final SurahHeaderBannerLayoutMetrics layout = layoutPolicy.calculate(
      SurahHeaderBannerLayoutInput(
        viewportWidth: viewportWidth,
        viewportHeight: viewportHeight,
        isLandscape: isLandscape,
        fontSizeMultiplier: headerFontSizeMultiplier,
      ),
    );
    final Widget bannerImage = headerImageFilter == null
        ? const Image(
            image: SurahHeaderBannerConstants.assetImage,
            fit: BoxFit.fill,
          )
        : ColorFiltered(
            colorFilter: headerImageFilter!,
            child: const Image(
              image: SurahHeaderBannerConstants.assetImage,
              fit: BoxFit.fill,
            ),
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
      child: SizedBox(
        height: layout.height,
        width: layout.width,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: bannerImage),
            Transform.translate(
              offset: Offset(0, layout.titleVerticalOffset),
              child: Text(
                glyphProvider.glyphForSurah(surahNumber),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: SurahHeaderBannerConstants.fontFamily,
                  package: SurahHeaderBannerConstants.packageName,
                  fontSize: layout.fontSize,
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
  static SurahHeaderBannerLayoutMetrics calculateLayout({
    required double viewportWidth,
    required double viewportHeight,
    required bool isLandscape,
    double fontSizeMultiplier =
        SurahHeaderBannerConstants.defaultFontSizeMultiplier,
  }) {
    return _defaultLayoutPolicy.calculate(
      SurahHeaderBannerLayoutInput(
        viewportWidth: viewportWidth,
        viewportHeight: viewportHeight,
        isLandscape: isLandscape,
        fontSizeMultiplier: fontSizeMultiplier,
      ),
    );
  }

  @visibleForTesting
  static double computeBannerHeight({
    required double viewportWidth,
    required double viewportHeight,
    required bool isLandscape,
  }) {
    return calculateLayout(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      isLandscape: isLandscape,
    ).height;
  }

  @visibleForTesting
  static double computeBannerWidth({
    required double viewportWidth,
    required double viewportHeight,
    required bool isLandscape,
  }) {
    return calculateLayout(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      isLandscape: isLandscape,
    ).width;
  }

  @visibleForTesting
  static double computeHorizontalPadding({
    required double viewportWidth,
    required double viewportHeight,
    required bool isLandscape,
  }) {
    return calculateLayout(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      isLandscape: isLandscape,
    ).horizontalPadding;
  }
}
