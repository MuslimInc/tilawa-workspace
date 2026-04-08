import 'package:flutter/material.dart';
import 'package:quran_image_flutter/verse_marker.dart';
import 'package:quran_image_flutter/verse_service.dart';

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
    final markers = verseService.getMarkersForPage(pageNumber);

    return Padding(
      padding: const EdgeInsets.only(top: 19, bottom: 19),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double pageWidth = constraints.maxWidth;
          final double pageHeight = constraints.maxHeight;
          final double lineHeight = pageWidth * _lineHeightRatio;

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
                  child: RepaintBoundary(
                    child: Image.asset(
                      'assets/quran_images/$pageNumber/${i + 1}.png',
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              for (final marker in markers)
                _AyahMarkerWidget(
                  marker: marker,
                  pageWidth: pageWidth,
                  pageHeight: pageHeight,
                  lineHeight: lineHeight,
                  yOffsets: yOffsets,
                ),
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

    final double xOffset = marker.centerX * pageWidth - markerW / 2;

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
