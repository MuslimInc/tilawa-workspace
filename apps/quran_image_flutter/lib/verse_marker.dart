import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/constants/surah_header_constants.dart';
import 'package:quran_image_flutter/domain/entities/verse_marker_data.dart';

import 'qcf_marker_path.dart';

class VerseMarker extends StatelessWidget {
  static final Map<int, String> _glyphCache = <int, String>{};
  static final Map<int, TextPainter> _textPainterCache = <int, TextPainter>{};

  final int verseNumber;
  final double width;
  final double height;

  const VerseMarker({
    super.key,
    required this.verseNumber,
    required this.width,
    required this.height,
  });

  static String _glyphFor(int number) {
    // quran_numbers.ttf contains exactly 286 pre-composed ligatures starting from U+E900.
    // 1 -> U+E900, 2 -> U+E901 ... 286 -> U+EA1D.
    final int clamped = number.clamp(1, 286);
    return _glyphCache.putIfAbsent(clamped, () {
      const int baseCodepoint = 0xE900;
      final int targetCodepoint = baseCodepoint + clamped - 1;
      return String.fromCharCode(targetCodepoint);
    });
  }

  static TextPainter _textPainterFor(int verseNumber, double width) {
    final widthKey = (width * 100).round();
    final cacheKey = (widthKey << 9) ^ verseNumber.clamp(1, 286);
    return _textPainterCache.putIfAbsent(cacheKey, () {
      final painter = TextPainter(
        text: TextSpan(
          text: _glyphFor(verseNumber),
          style: TextStyle(
            fontFamily: 'QuranNumbers',
            fontSize: width,
            color: const Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      )..layout();
      return painter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: const _QcfMarkerPainter(),
            isComplex: true,
            willChange: false,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(
              _glyphFor(verseNumber),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'QuranNumbers',
                fontSize: width,
                color: const Color(0xFF5D4037),
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VerseMarkersOverlay extends StatelessWidget {
  const VerseMarkersOverlay({
    super.key,
    required this.markers,
    required this.pageWidth,
    required this.lineHeight,
    required this.yOffsets,
  });

  final List<VerseMarkerData> markers;
  final double pageWidth;
  final double lineHeight;
  final List<double> yOffsets;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _VerseMarkersPainter(
          markers: markers,
          pageWidth: pageWidth,
          lineHeight: lineHeight,
          yOffsets: yOffsets,
        ),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

class _QcfMarkerPainter extends CustomPainter {
  static final Map<int, _CachedMarkerPaths> _pathCache =
      <int, _CachedMarkerPaths>{};

  const _QcfMarkerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cachedPaths = _pathsFor(size);

    // Provide a subtle shadow behind the glyph without expensive blurring
    canvas.drawPath(
      cachedPaths.shadow,
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Draw the main QCF marker with a premium golden color
    final fillPaint = Paint()
      ..color = const Color(0xFFC5A358)
      ..style = PaintingStyle.fill;

    canvas.drawPath(cachedPaths.main, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  static _CachedMarkerPaths _pathsFor(Size size) {
    final key =
        (size.width * 1000).round() ^ ((size.height * 1000).round() << 1);
    return _pathCache.putIfAbsent(key, () {
      final mainPath = getQcfMarkerPath(size);
      final shadowPath = mainPath.shift(
        Offset(size.width * 0.02, size.width * 0.02),
      );
      return _CachedMarkerPaths(main: mainPath, shadow: shadowPath);
    });
  }
}

class _VerseMarkersPainter extends CustomPainter {
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.15);
  static final Paint _fillPaint = Paint()
    ..color = const Color(0xFFC5A358)
    ..style = PaintingStyle.fill;

  const _VerseMarkersPainter({
    required this.markers,
    required this.pageWidth,
    required this.lineHeight,
    required this.yOffsets,
  });

  final List<VerseMarkerData> markers;
  final double pageWidth;
  final double lineHeight;
  final List<double> yOffsets;

  @override
  void paint(Canvas canvas, Size size) {
    if (markers.isEmpty) {
      return;
    }

    final markerWidth = pageWidth * 0.05138889;
    final markerHeight = pageWidth * 0.06527778;
    final markerPaths = _QcfMarkerPainter._pathsFor(
      Size(markerWidth, markerHeight),
    );

    for (final marker in markers) {
      final xOffset = (marker.centerX * pageWidth - markerWidth / 2).clamp(
        0.0,
        pageWidth - markerWidth,
      );
      final lineIndex = marker.line.clamp(
        0,
        SurahHeaderConstants.lastLineIndex,
      );
      final yCenter = yOffsets[lineIndex] + lineHeight / 2;
      final yOffset = yCenter - markerHeight / 2;
      final textPainter = VerseMarker._textPainterFor(marker.ayah, markerWidth);

      canvas.save();
      canvas.translate(xOffset, yOffset);
      canvas.drawPath(markerPaths.shadow, _shadowPaint);
      canvas.drawPath(markerPaths.main, _fillPaint);
      textPainter.paint(
        canvas,
        Offset(
          (markerWidth - textPainter.width) / 2,
          (markerHeight - textPainter.height) / 2 + 1.0,
        ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _VerseMarkersPainter oldDelegate) {
    return oldDelegate.markers != markers ||
        oldDelegate.pageWidth != pageWidth ||
        oldDelegate.lineHeight != lineHeight ||
        !listEquals(oldDelegate.yOffsets, yOffsets);
  }
}

class _CachedMarkerPaths {
  const _CachedMarkerPaths({required this.main, required this.shadow});

  final Path main;
  final Path shadow;
}
