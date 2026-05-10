import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran_image/core/constants/surah_header_constants.dart';
import 'package:quran_image/domain/entities/verse_marker_data.dart';

import 'qcf_marker_path.dart';
import 'verse_marker_layout.dart';

class VerseMarker extends StatelessWidget {
  static const int _maxVerseNumber = 286;
  static const int _warmUpBatchSize = 20;
  static final Set<int> _warmedMarkerSizes = <int>{};
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
    final int clamped = number.clamp(1, _maxVerseNumber);
    return _glyphCache.putIfAbsent(clamped, () {
      const int baseCodepoint = 0xE900;
      final int targetCodepoint = baseCodepoint + clamped - 1;
      return String.fromCharCode(targetCodepoint);
    });
  }

  static Future<void> warmUpAll({
    required double markerWidth,
    int batchSize = _warmUpBatchSize,
    Duration yieldDelay = Duration.zero,
  }) async {
    await warmUpNumbers(
      markerWidth: markerWidth,
      verseNumbers: Iterable<int>.generate(_maxVerseNumber, (i) => i + 1),
      batchSize: batchSize,
      yieldDelay: yieldDelay,
    );
  }

  /// Warms a targeted set of ayah markers at the actual render size.
  ///
  /// This is used on startup to cover only the initial page and the immediate
  /// swipe target. The remaining ayah numbers are warmed in the background once
  /// the reader is already interactive.
  static Future<void> warmUpNumbers({
    required double markerWidth,
    required Iterable<int> verseNumbers,
    int batchSize = _warmUpBatchSize,
    Duration yieldDelay = Duration.zero,
  }) async {
    final markerHeight = markerWidth * (0.06527778 / 0.05138889);
    final markerSize = Size(markerWidth, markerHeight);

    // Pre-compute paths (keyed by size) — triggers Impeller tessellation.
    final paths = _QcfMarkerPainter._pathsFor(markerSize);
    final numbers =
        verseNumbers
            .map((number) => number.clamp(1, _maxVerseNumber))
            .toSet()
            .toList()
          ..sort();

    // Pre-populate TextPainters for the requested verse numbers at this size.
    // _textPainterFor calls layout() on first creation. We yield every
    // _warmUpBatchSize iterations so the UI thread never blocks for more than
    // one frame budget at a time (~8 ms per batch at 60 Hz).
    for (var i = 0; i < numbers.length; i++) {
      _textPainterFor(numbers[i], markerWidth);
      if ((i + 1) % batchSize == 0) {
        await Future<void>.delayed(yieldDelay);
      }
    }

    final markerSizeKey =
        (markerWidth * 1000).round() ^ ((markerHeight * 1000).round() << 1);
    if (_warmedMarkerSizes.add(markerSizeKey)) {
      // Draw one marker on an offscreen canvas so Impeller compiles render
      // pipelines and tessellates the path before the first real paint.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, markerWidth * 2, markerHeight * 2),
      );
      canvas.drawPath(paths.shadow, _VerseMarkersPainter._shadowPaint);
      canvas.drawPath(paths.main, _VerseMarkersPainter._fillPaint);
      _textPainterFor(
        numbers.isEmpty ? 1 : numbers.first,
        markerWidth,
      ).paint(canvas, Offset.zero);
      recorder.endRecording().dispose();
    }
  }

  /// Deprecated warm-up that only pre-loads ayah #1. Use [warmUpAll] instead.
  static Future<void> warmUpFont({double markerWidth = 20.0}) =>
      warmUpAll(markerWidth: markerWidth);

  static TextPainter _textPainterFor(int verseNumber, double width) {
    final widthKey = (width * 100).round();
    final cacheKey = (widthKey << 9) ^ verseNumber.clamp(1, _maxVerseNumber);
    return _textPainterCache.putIfAbsent(cacheKey, () {
      final painter = TextPainter(
        text: TextSpan(
          text: _glyphFor(verseNumber),
          style: TextStyle(
            fontFamily: 'QuranNumbers',
            package: 'quran_image',
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
                package: 'quran_image',
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

    // Use the painted overlay width — it must match line images (full stack
    // width). Relying on [pageWidth] alone can drift from [size.width] on
    // narrow devices when layout and MediaQuery/View metrics disagree.
    final layoutWidth = size.width;
    final markerWidth = VerseMarkerLayout.markerWidth(layoutWidth);
    final markerHeight = VerseMarkerLayout.markerHeight(layoutWidth);
    final markerPaths = _QcfMarkerPainter._pathsFor(
      Size(markerWidth, markerHeight),
    );

    for (final marker in markers) {
      final xOffset = VerseMarkerLayout.markerLeftOffset(
        centerX: marker.centerX,
        layoutWidth: layoutWidth,
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
