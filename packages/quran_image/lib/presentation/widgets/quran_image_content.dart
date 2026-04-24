import 'package:flutter/material.dart';
import 'package:quran_image/core/constants/surah_header_constants.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/widgets/widgets.dart';
import 'package:quran_image/verse_marker.dart';

class QuranImageContent extends StatelessWidget {
  const QuranImageContent({
    super.key,
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.lineHeight,
    required this.yOffsets,
    required this.headers,
    required this.markers,
    required this.lineProviders,
    required this.surahHeaderLayoutPolicy,
    required this.imageCacheRepository,
    required this.devicePixelRatio,
    this.backgroundColor = const Color(0xFFFFF8ED),
  });

  final int pageNumber;
  final double pageWidth;
  final double pageHeight;
  final double lineHeight;
  final List<double> yOffsets;
  final List<SurahHeaderData> headers;
  final List<VerseMarkerData> markers;
  final List<ImageProvider<Object>?> lineProviders;
  final SurahHeaderBannerLayoutPolicy surahHeaderLayoutPolicy;
  final QuranImageCacheRepository imageCacheRepository;
  final double devicePixelRatio;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final header in headers)
            Positioned(
              key: ValueKey<String>('header:${header.lineIndex}'),
              left: 0,
              right: 0,
              top: yOffsets[header.lineIndex],
              height: lineHeight,
              child: SurahHeaderBanner(
                header: header,
                layoutPolicy: surahHeaderLayoutPolicy,
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                lineHeight: lineHeight,
                bannerLocalPath: imageCacheRepository
                    .surahHeaderBannerFilePath(),
                devicePixelRatio: devicePixelRatio,
              ),
            ),
          for (var index = 0; index < SurahHeaderConstants.lineCount; index++)
            Positioned(
              key: ValueKey<int>(index),
              left: 0,
              right: 0,
              top: yOffsets[index],
              height: lineHeight,
              child: QuranLineImage(provider: lineProviders[index]),
            ),
          if (markers.isNotEmpty)
            Positioned.fill(
              key: const ValueKey<String>('markers'),
              child: RepaintBoundary(
                child: VerseMarkersOverlay(
                  markers: markers,
                  pageWidth: pageWidth,
                  lineHeight: lineHeight,
                  yOffsets: yOffsets,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
