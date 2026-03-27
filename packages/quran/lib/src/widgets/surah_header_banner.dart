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
  static const double _horizontalInsetRatio = 14 / 720;
  static const double _verticalOffset = -2;
  static const double _landscapeHeightMultiplier = 1.22;
  static const double _referenceBannerHeightMultiplier = 1.22;
  static const double _smallViewportHeight = 1200;
  static const double _smallViewportBannerHeight = 59;
  static const double _largeViewportHeight = 1280;
  static const double _largeViewportBannerHeight = 77;

  @override
  Widget build(BuildContext context) {
    final renderStartTime = DateTime.now();
    // The banner should be slightly shorter than the full line height
    // to provide visual separation between verses and headers.

    final Widget result = RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = MediaQuery.sizeOf(context).height;
          final double devicePixelRatio = MediaQuery.devicePixelRatioOf(
            context,
          );
          final isPortrait =
              MediaQuery.orientationOf(context) == Orientation.portrait;
          final double horizontalInset =
              constraints.maxWidth * _horizontalInsetRatio;
          final double bannerHeight = computeBannerHeight(
            viewportHeight: viewportHeight,
            devicePixelRatio: devicePixelRatio,
            isPortrait: isPortrait,
            lineHeight: lineHeight,
          );
          final double headerFontSize =
              bannerHeight *
              (headerFontSizeMultiplier / _referenceBannerHeightMultiplier);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalInset),
            child: SizedBox(
              height: bannerHeight,
              width: double.infinity,
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
                  // Centered precisely within the banner frame.
                  Transform.translate(
                    offset: const Offset(
                      0,
                      _verticalOffset,
                    ), // Fine-tune vertical alignment
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
    required double viewportHeight,
    required double devicePixelRatio,
    required bool isPortrait,
    required double lineHeight,
  }) {
    if (!isPortrait) {
      return lineHeight * _landscapeHeightMultiplier;
    }
    final double viewportPhysicalHeight = viewportHeight * devicePixelRatio;
    final double bannerPhysicalHeight = _bannerPhysicalHeightForViewport(
      viewportPhysicalHeight,
    );
    return bannerPhysicalHeight / devicePixelRatio;
  }

  @visibleForTesting
  static double bannerPhysicalHeightForViewport(double viewportPhysicalHeight) {
    return _bannerPhysicalHeightForViewport(viewportPhysicalHeight);
  }

  static double _bannerPhysicalHeightForViewport(
    double viewportPhysicalHeight,
  ) {
    final double t =
        ((viewportPhysicalHeight - _smallViewportHeight) /
                (_largeViewportHeight - _smallViewportHeight))
            .clamp(0.0, 1.0);
    return _smallViewportBannerHeight +
        ((_largeViewportBannerHeight - _smallViewportBannerHeight) * t);
  }
}
