import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import 'package:quran_image_flutter/verse_marker.dart';

/// Renders a full Quran page using the same layout algorithm as the Ayah app.
///
/// The Ayah app's `QuranLineLayout` (Kotlin) places each line at:
///   y = floor((pageHeight - lineHeight) / 14 * lineIndex)
/// where:
///   lineHeight = pageWidth * 174 / 1080
///   lineIndex  = 0-based (0–14)
///
/// Each line image is the same 1440×232 aspect ratio → ratio = 232/1440 ≈ 0.1611.
class QuranImagePage extends StatelessWidget {
  static const double _lineHeightRatio = 174.0 / 1080.0;
  static const int _lineCount = 15;

  final int pageNumber;

  const QuranImagePage({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    debugPrint('[PageViewJumpPerformance] QuranImagePage.build started for page $pageNumber');
    final start = DateTime.now();
    final markers = sl<VerseMarkerRepository>().getMarkersForPage(pageNumber);
    final diff = DateTime.now().difference(start);
    debugPrint('[PageViewJumpPerformance] Fetched markers for page $pageNumber in ${diff.inMicroseconds}us');


    return Padding(
      padding: const EdgeInsets.only(top: 19, bottom: 19),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double pageWidth = constraints.maxWidth;
          final double pageHeight = constraints.maxHeight;
          final double lineHeight = pageWidth * _lineHeightRatio;

          // Calculate the optimal physical width to force the C++ native decoder 
          // to dramatically scale down the 1440px images BEFORE hitting the GPU VRAM bus.
          final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
          final int cacheWidth = (pageWidth * devicePixelRatio).round();

          const double lastLineIndex = _lineCount - 1;
          final List<double> yOffsets = List.generate(_lineCount, (i) {
            return ((pageHeight - lineHeight) / lastLineIndex * i)
                .floorToDouble();
          });

          return Stack(
            children: [
              for (var i = 0; i < _lineCount; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: yOffsets[i],
                  height: lineHeight,
                  child: Image.asset(
                    'assets/quran_images/$pageNumber/${i + 1}.png',
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    cacheWidth: cacheWidth,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (frame != null && !wasSynchronouslyLoaded && frame == 0) {
                        // Log exactly when the native decoder finishes unpacking an image to VRAM
                        debugPrint('[PageViewJumpPerformance] Image ${i + 1} for page $pageNumber completed async decode');
                      }
                      return child;
                    },
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),

              for (final marker in markers)
                () {
                  debugPrint('[PageViewJumpPerformance] Laying out AyahMarkerWidget for Ayah ${marker.ayah} on Page $pageNumber');
                  return _AyahMarkerWidget(
                    marker: marker,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight,
                    lineHeight: lineHeight,
                    yOffsets: yOffsets,
                  );
                }(),
            ],
          );
        },
      ),
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
    final int idx = marker.line.clamp(0, 14);
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
