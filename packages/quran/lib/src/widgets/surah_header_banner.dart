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

  @override
  Widget build(BuildContext context) {
    final renderStartTime = DateTime.now();
    // The banner should be slightly shorter than the full line height
    // to provide visual separation between verses and headers.

    final result = RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: lineHeight,
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
                offset: const Offset(0, -1), // Fine-tune vertical alignment
                child: Text(
                  String.fromCharCode(0xF100 + surahNumber - 1),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'QCF_BSML',
                    package: 'quran',
                    fontSize: lineHeight * headerFontSizeMultiplier,
                    color:
                        headerTextColor ??
                        Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
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
}
