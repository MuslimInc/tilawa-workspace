import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/constants/quran_image_asset_constants.dart';
import 'package:quran_image_flutter/core/constants/surah_header_constants.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import 'package:quran_image_flutter/verse_marker.dart';

/// Renders a full Quran page using the same layout algorithm as the Ayah app.
///
/// The Ayah app's `QuranLineLayout` (Kotlin) places each line at:
///   y = floor((pageHeight - lineHeight) / 14 * lineIndex)
/// where:
///   lineHeight is derived from the rendered page width.
///   lineIndex  = 0-based (0–14)
///
/// Each line image is the same 1440×232 aspect ratio → ratio = 232/1440 ≈ 0.1611.
class QuranImagePage extends StatelessWidget {
  final int pageNumber;
  final SurahHeaderBannerLayoutPolicy surahHeaderLayoutPolicy;

  const QuranImagePage({
    super.key,
    required this.pageNumber,
    this.surahHeaderLayoutPolicy =
        const CalibratedSurahHeaderBannerLayoutPolicy(),
  });

  @override
  Widget build(BuildContext context) {
    final markers = sl<VerseMarkerRepository>().getMarkersForPage(pageNumber);
    final headers = sl<SurahHeaderRepository>().getHeadersForPage(pageNumber);
    final imageCacheRepository = sl<QuranImageCacheRepository>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double pageWidth = constraints.maxWidth;
        final double pageHeight = constraints.maxHeight;
        final bool isLandscape = pageWidth > pageHeight;

        // Always use the Ayah app formula: lineHeight derives from width.
        // In landscape the total content height exceeds the viewport,
        // so we wrap in a scroll view.
        final double lineHeight = surahHeaderLayoutPolicy
            .lineHeightForPageWidth(pageWidth);

        // Calculate the optimal physical width to force the C++ native decoder
        // to dramatically scale down the 1440px images BEFORE hitting the GPU VRAM bus.
        final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final int cacheWidth = (pageWidth * devicePixelRatio).round();

        // In landscape, content overflows — use total content height for layout.
        // There are no gaps; lines fill tightly.
        final double layoutHeight = isLandscape
            ? lineHeight * SurahHeaderConstants.lineCount
            : pageHeight;

        final double lastLineIndex = SurahHeaderConstants.lastLineIndex
            .toDouble();
        final List<double> yOffsets = List.generate(
          SurahHeaderConstants.lineCount,
          (i) {
            return ((layoutHeight - lineHeight) / lastLineIndex * i);
          },
        );

        final content = SizedBox(
          width: pageWidth,
          height: layoutHeight,
          child: Stack(
            children: [
              // Surah header banner behind the surah name lines.
              for (final header in headers)
                Positioned(
                  left: 0,
                  right: 0,
                  top: yOffsets[header.lineIndex],
                  height: lineHeight,
                  child: _SurahHeaderBanner(
                    header: header,
                    lineHeight: lineHeight,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight,
                    layoutPolicy: surahHeaderLayoutPolicy,
                    imageCacheRepository: imageCacheRepository,
                  ),
                ),

              for (var i = 0; i < SurahHeaderConstants.lineCount; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: yOffsets[i],
                  child: _QuranLineImage(
                    imagePath: imageCacheRepository.lineImageFilePath(
                      pageNumber: pageNumber,
                      oneBasedLineNumber: i + 1,
                    ),
                    cacheWidth: cacheWidth,
                  ),
                ),

              for (final marker in markers)
                _AyahMarkerWidget(
                  marker: marker,
                  pageWidth: pageWidth,
                  pageHeight: layoutHeight,
                  lineHeight: lineHeight,
                  yOffsets: yOffsets,
                ),
            ],
          ),
        );

        // In landscape, content is taller than the viewport — scroll vertically.
        if (isLandscape) {
          return SingleChildScrollView(child: content);
        }
        return content;
      },
    );
  }
}

/// Renders the decorative Surah header banner image.
///
/// Banner width is computed using a linear regression model calibrated
/// against Figma measurements from the Ayah app across multiple devices.
/// Height follows the intrinsic aspect ratio of the banner image asset.
class _SurahHeaderBanner extends StatelessWidget {
  const _SurahHeaderBanner({
    required this.header,
    required this.lineHeight,
    required this.pageWidth,
    required this.pageHeight,
    required this.layoutPolicy,
    required this.imageCacheRepository,
  });

  final SurahHeaderData header;
  final double lineHeight;
  final double pageWidth;
  final double pageHeight;
  final SurahHeaderBannerLayoutPolicy layoutPolicy;
  final QuranImageCacheRepository imageCacheRepository;

  @override
  Widget build(BuildContext context) {
    final SurahHeaderBannerLayoutMetrics metrics = layoutPolicy.calculate(
      SurahHeaderBannerLayoutInput(
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        lineHeight: lineHeight,
        inkCenterYFraction: header.inkCenterYFraction,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, metrics.verticalOffset),
          child: SizedBox(
            height: metrics.bannerHeight,
            width: metrics.bannerWidth,
            child: _CachedOrRemoteImage(
              localPath: imageCacheRepository.surahHeaderBannerFilePath(),
              remoteUrl: QuranImageAssetConstants.remoteSurahHeaderBannerUrl,
              gaplessPlayback: true,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranLineImage extends StatelessWidget {
  const _QuranLineImage({required this.imagePath, required this.cacheWidth});

  final String? imagePath;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null) {
      return const SizedBox.shrink();
    }

    return Image.file(
      File(path),
      fit: BoxFit.fill,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

class _CachedOrRemoteImage extends StatelessWidget {
  const _CachedOrRemoteImage({
    required this.localPath,
    required this.remoteUrl,
    required this.fit,
    required this.gaplessPlayback,
  });

  final String? localPath;
  final String remoteUrl;
  final BoxFit fit;
  final bool gaplessPlayback;

  @override
  Widget build(BuildContext context) {
    final path = localPath;
    if (path != null) {
      return Image.file(
        File(path),
        fit: fit,
        gaplessPlayback: gaplessPlayback,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    return Image.network(
      remoteUrl,
      fit: fit,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

class _AyahMarkerWidget extends StatelessWidget {
  final VerseMarkerData marker;
  final double pageWidth;
  final double pageHeight;
  final double lineHeight;
  final List<double> yOffsets;

  const _AyahMarkerWidget({
    required this.marker,
    required this.pageWidth,
    required this.pageHeight,
    required this.lineHeight,
    required this.yOffsets,
  });

  @override
  Widget build(BuildContext context) {
    // Precise: Based on Ayah app measurement of 37x47 px on a 720 px-wide screen.
    final double markerW = pageWidth * 0.05138889;
    final double markerH = pageWidth * 0.06527778;

    final double xOffset = (marker.centerX * pageWidth - markerW / 2).clamp(
      0.0,
      pageWidth - markerW,
    );

    // marker.line is the 0-based image-file index (0–14).
    // yCenter = top of that line's slot + half a line height (vertical centre).
    final int idx = marker.line.clamp(0, SurahHeaderConstants.lastLineIndex);
    final double yCenter = yOffsets[idx] + lineHeight / 2;

    return Positioned(
      left: xOffset,
      top: yCenter - markerH / 2,
      child: VerseMarker(
        verseNumber: marker.ayah,
        width: markerW,
        height: markerH,
      ),
    );
  }
}
