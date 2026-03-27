import 'package:flutter/material.dart';

import '../helpers/app_logger.dart';

class SurahHeaderBanner extends StatelessWidget {
  const SurahHeaderBanner({
    super.key,
    required this.surahNumber,
    required this.lineHeight,
    this.headerImageFilter,
    this.headerTextColor,
    this.headerFontSizeMultiplier = 0.45,
  });

  final int surahNumber;
  final double lineHeight;
  final ColorFilter? headerImageFilter;
  final Color? headerTextColor;
  final double headerFontSizeMultiplier;

  static const AssetImage _bannerImage = AssetImage(
    'assets/mainframe.png',
    package: 'quran',
  );
  static const double _verticalOffset = -2;
  static const double _referenceBannerHeightMultiplier = 1.22;

  static const double _portraitRatio = 0.108;
  static const double _landscapeRatio = 0.094;

  @override
  Widget build(BuildContext context) {
    final renderStartTime = DateTime.now();

    final Widget result = RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Size screenSize = MediaQuery.sizeOf(context);
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;

          final double bannerHeight = computeBannerHeight(
            screenSize: screenSize,
            isLandscape: isLandscape,
          );
          final double bannerWidth = constraints.maxWidth;
          final double headerFontSize =
              bannerHeight *
              (headerFontSizeMultiplier / _referenceBannerHeightMultiplier);

          return SizedBox(
            height: bannerHeight,
            width: bannerWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: headerImageFilter != null
                      ? ColorFiltered(
                          colorFilter: headerImageFilter!,
                          child: const Image(
                            image: _bannerImage,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.low,
                          ),
                        )
                      : const Image(
                          image: _bannerImage,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.low,
                        ),
                ),
                // The Surah name calligraphy from QCF_BSML font.
                Transform.translate(
                  offset: const Offset(0, _verticalOffset),
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
          );
        },
      ),
    );

    final Duration renderDuration = DateTime.now().difference(renderStartTime);
    if (renderDuration.inMilliseconds > 8) {
      logger.d(
        '[PageContent] SurahHeaderBanner $surahNumber build took ${renderDuration.inMilliseconds}ms',
      );
    }
    return result;
  }

  @visibleForTesting
  static double computeBannerHeight({
    required Size screenSize,
    required bool isLandscape,
  }) {
    if (isLandscape) {
      return (screenSize.width * _landscapeRatio).roundToDouble();
    }
    return (screenSize.width * _portraitRatio).roundToDouble();
  }
}
