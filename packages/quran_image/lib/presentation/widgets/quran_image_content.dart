import 'package:flutter/material.dart';
import 'package:quran_image/core/constants/surah_header_constants.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/widgets/widgets.dart';
import 'package:quran_image/verse_marker.dart';

class QuranImageContent extends StatelessWidget {
  const QuranImageContent({
    super.key,
    required this.pageNumber,
    required this.layoutMetrics,
    required this.headers,
    required this.markers,
    required this.lineProviders,
    required this.surahHeaderLayoutPolicy,
    required this.imageCacheRepository,
    required this.devicePixelRatio,
    this.backgroundColor,
    this.headerImageFilter,
  });

  final int pageNumber;
  final QuranPageLayoutMetrics layoutMetrics;
  final List<SurahHeaderData> headers;
  final List<VerseMarkerData> markers;
  final List<ImageProvider<Object>?> lineProviders;
  final SurahHeaderBannerLayoutPolicy surahHeaderLayoutPolicy;
  final QuranImageCacheRepository imageCacheRepository;
  final double devicePixelRatio;
  final Color? backgroundColor;
  final ColorFilter? headerImageFilter;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('QuranImageContent');
    final contentStack = ColoredBox(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final header in headers)
            Positioned(
              key: ValueKey<String>('header:${header.lineIndex}'),
              left: 0,
              right: 0,
              top: layoutMetrics.yOffsets[header.lineIndex],
              height: layoutMetrics.lineHeight,
              child: SurahHeaderBanner(
                header: header,
                layoutPolicy: surahHeaderLayoutPolicy,
                pageWidth: layoutMetrics.pageWidth,
                pageHeight: layoutMetrics.pageHeight,
                lineHeight: layoutMetrics.lineHeight,
                bannerLocalPath: imageCacheRepository
                    .surahHeaderBannerFilePath(),
                devicePixelRatio: devicePixelRatio,
                colorFilter: headerImageFilter,
              ),
            ),
          for (var index = 0; index < SurahHeaderConstants.lineCount; index++)
            Positioned(
              key: ValueKey<int>(index),
              left: 0,
              right: 0,
              top: layoutMetrics.yOffsets[index],
              height: layoutMetrics.lineHeight,
              child: QuranLineImage(
                provider: lineProviders[index],
                colorFilter: headerImageFilter,
              ),
            ),
          if (markers.isNotEmpty)
            Positioned.fill(
              key: const ValueKey<String>('markers'),
              child: RepaintBoundary(
                child: headerImageFilter != null
                    ? ColorFiltered(
                        colorFilter: headerImageFilter!,
                        child: VerseMarkersOverlay(
                          markers: markers,
                          pageWidth: layoutMetrics.pageWidth,
                          lineHeight: layoutMetrics.lineHeight,
                          yOffsets: layoutMetrics.yOffsets,
                        ),
                      )
                    : VerseMarkersOverlay(
                        markers: markers,
                        pageWidth: layoutMetrics.pageWidth,
                        lineHeight: layoutMetrics.lineHeight,
                        yOffsets: layoutMetrics.yOffsets,
                      ),
              ),
            ),
        ],
      ),
    );

    if (layoutMetrics.isLandscape) {
      return SingleChildScrollView(
        child: SizedBox(
          height: layoutMetrics.lineHeight * SurahHeaderConstants.lineCount,
          child: contentStack,
        ),
      );
    }

    return contentStack;
  }
}
