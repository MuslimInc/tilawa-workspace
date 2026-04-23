import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/models/quran_word_metadata.dart';
import '../../helpers/app_logger.dart';
import '../layout/quran_line_layout.dart';

const bool _kDebugQuranLineGuides = true;
const bool _kDebugQuranLineLogs = true;

/// Metadata for a single word within the consolidated page painter.
///
/// Extends [QuranWordMetadata] with the y-offset so the merged painter
/// can route hit-tests to the correct line's [TextPainter].
@immutable
class PageWordMetadata extends Equatable {
  const PageWordMetadata({
    required this.lineIndex,
    required this.word,
    required this.yOffset,
  });

  final int lineIndex;
  final QuranWordMetadata word;
  final double yOffset;

  @override
  List<Object?> get props => [lineIndex, word, yOffset];
}

/// A single-pass painter for an entire Quran page's text lines.
///
/// Instead of 15 separate [CustomPaint] widgets (one per [QuranLine]),
/// this widget paints all [TextPainter]s in a single `paint()` call.
/// This reduces the raster thread's render-object traversal from ~15
/// calls to 1, cutting compositing overhead during swipe animations.
class QuranPagePainter extends StatefulWidget {
  const QuranPagePainter({
    super.key,
    required this.painters,
    required this.lineSpacing,
    this.width,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
  });

  /// Each entry: (textPainter, metadata) for one line.
  final List<(TextPainter, List<QuranWordMetadata>)> painters;
  final double lineSpacing;
  final double? width;
  final void Function(int surah, int verse)? onLongPress;
  final void Function(int surah, int verse)? onLongPressUp;
  final void Function(int surah, int verse)? onLongPressCancel;
  final void Function(int surah, int verse, LongPressStartDetails details)?
  onLongPressDown;

  @override
  State<QuranPagePainter> createState() => _QuranPagePainterState();
}

class _QuranPagePainterState extends State<QuranPagePainter> {
  final GlobalKey _paintKey = GlobalKey();
  QuranWordMetadata? _activeWord;

  /// Pre-computed y-offsets for each line.
  late List<double> _yOffsets;

  /// Total height of all lines + spacing.
  late double _totalHeight;

  /// Trims extra font leading above the first line and below the last line.
  late double _topInset;
  late double _bottomInset;

  /// Fixed paint width shared by every line.
  late double _paintWidth;

  late List<QuranLineAlignment?> _alignments;

  /// Cached recorded [ui.Picture] from the first paint call.
  /// Wrapped in a mutable cache class so CustomPainter can track it across repaints.
  _TextPictureCache _pictureCache = _TextPictureCache();

  @override
  void initState() {
    super.initState();
    _computeLayout();
  }

  @override
  void didUpdateWidget(QuranPagePainter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.painters, widget.painters) ||
        oldWidget.lineSpacing != widget.lineSpacing ||
        oldWidget.width != widget.width) {
      _invalidatePictureCache();
      _computeLayout();
    }
  }

  @override
  void dispose() {
    _pictureCache.picture?.dispose();
    _pictureCache.picture = null;
    super.dispose();
  }

  void _invalidatePictureCache() {
    _pictureCache.picture?.dispose();
    _pictureCache = _TextPictureCache();
  }

  void _computeLayout() {
    final offsets = <double>[];
    double y = 0;
    double maxW = 0;
    for (var i = 0; i < widget.painters.length; i++) {
      if (i > 0) y += widget.lineSpacing;
      offsets.add(y);
      final TextPainter painter = widget.painters[i].$1;
      y += painter.height;
      if (painter.width > maxW) maxW = painter.width;
    }
    _yOffsets = offsets;
    _topInset = _edgeLeadingInset(
      widget.painters.isEmpty ? null : widget.painters.first.$1,
    );
    _bottomInset = _edgeLeadingInset(
      widget.painters.isEmpty ? null : widget.painters.last.$1,
    );
    _totalHeight = (y - _topInset - _bottomInset).clamp(0.0, double.infinity);
    _paintWidth = switch (widget.width) {
      final double width when width.isFinite && width > 0 => width,
      _ => maxW,
    };
    _alignments = _computeAlignments();

    if (_kDebugQuranLineLogs) {
      _logLineMetrics();
    }
  }

  void _logLineMetrics() {
    final buffer = StringBuffer(
      '[QURAN_DEBUG][PAINTER] lines=${widget.painters.length} '
      'totalHeight=${_totalHeight.toStringAsFixed(1)} '
      'paintWidth=${_paintWidth.toStringAsFixed(1)} '
      'topInset=${_topInset.toStringAsFixed(1)} '
      'bottomInset=${_bottomInset.toStringAsFixed(1)} '
      'lineSpacing=${widget.lineSpacing.toStringAsFixed(1)}',
    );

    for (var i = 0; i < widget.painters.length; i++) {
      final TextPainter painter = widget.painters[i].$1;
      final List<LineMetrics> metrics = painter.computeLineMetrics();
      final LineMetrics? line = metrics.isEmpty ? null : metrics.first;
      final double yTop = _yOffsets[i] - _topInset;
      final double yBottom = yTop + painter.height;
      buffer.write(
        '\n  line#$i y=${yTop.toStringAsFixed(1)}..${yBottom.toStringAsFixed(1)} '
        'height=${painter.height.toStringAsFixed(1)} '
        'width=${painter.width.toStringAsFixed(1)} '
        'ascent=${line?.ascent.toStringAsFixed(1) ?? 'n/a'} '
        'descent=${line?.descent.toStringAsFixed(1) ?? 'n/a'} '
        'lineHeight=${line?.height.toStringAsFixed(1) ?? 'n/a'} '
        'baseline=${line?.baseline.toStringAsFixed(1) ?? 'n/a'} '
        'glyphs=${widget.painters[i].$2.length}',
      );
    }

    logger.w(buffer.toString());
  }

  double _edgeLeadingInset(TextPainter? painter) {
    if (painter == null) return 0;
    final List<LineMetrics> metrics = painter.computeLineMetrics();
    if (metrics.isEmpty) return 0;

    final LineMetrics line = metrics.first;
    final double leading = (line.height - line.ascent - line.descent).clamp(
      0.0,
      double.infinity,
    );
    return leading / 2;
  }

  List<QuranLineAlignment?> _computeAlignments() {
    final List<QuranLineVisualBounds?> positionedBounds = [];
    final List<QuranLineVisualBounds?> sourceBounds = [];

    for (final (TextPainter painter, _) in widget.painters) {
      final QuranLineVisualBounds? source = quranLineVisualBoundsFor(painter);
      sourceBounds.add(source);
      if (source == null) {
        positionedBounds.add(null);
        continue;
      }

      final double naturalDx = (_paintWidth - painter.width) / 2;
      positionedBounds.add(source.shift(naturalDx));
    }

    final QuranLineVisualBounds? target = quranLineTargetBoundsFor(
      positionedBounds,
    );
    if (target == null) {
      return List<QuranLineAlignment?>.filled(widget.painters.length, null);
    }

    return sourceBounds
        .map((source) {
          if (source == null) return null;
          return QuranLineAlignment(source: source, target: target);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (LongPressStartDetails details) {
        final QuranWordMetadata? word = _findWordAtOffset(
          details.globalPosition,
        );
        if (word != null) {
          _activeWord = word;
          widget.onLongPressDown?.call(word.surah, word.verse, details);
        }
      },
      onLongPress: () {
        final QuranWordMetadata? word = _activeWord;
        if (word != null) {
          widget.onLongPress?.call(word.surah, word.verse);
        }
      },
      onLongPressUp: () {
        final QuranWordMetadata? word = _activeWord;
        if (word != null) {
          widget.onLongPressUp?.call(word.surah, word.verse);
        }
        _activeWord = null;
      },
      onLongPressCancel: () {
        final QuranWordMetadata? word = _activeWord;
        if (word != null) {
          widget.onLongPressCancel?.call(word.surah, word.verse);
        }
        _activeWord = null;
      },
      child: Center(
        child: SizedBox(
          width: _paintWidth,
          height: _totalHeight,
          child: KeyedSubtree(
            key: _paintKey,
            child: CustomPaint(
              painter: _AllLinesPainter(
                painters: widget.painters,
                alignments: _alignments,
                yOffsets: _yOffsets,
                topInset: _topInset,
                pictureCache: _pictureCache,
              ),
            ),
          ),
        ),
      ),
    );
  }

  QuranWordMetadata? _findWordAtOffset(Offset globalPosition) {
    final BuildContext? ctx = _paintKey.currentContext;
    if (ctx == null) return null;

    final RenderObject? renderObj = ctx.findRenderObject();
    if (renderObj == null || renderObj is! RenderBox) return null;

    final Offset localPos = renderObj.globalToLocal(globalPosition);

    // Find which line the tap landed on.
    for (var i = 0; i < widget.painters.length; i++) {
      final double yTop = _yOffsets[i] - _topInset;
      final TextPainter painter = widget.painters[i].$1;
      final double yBottom = yTop + painter.height;

      if (localPos.dy >= yTop && localPos.dy < yBottom) {
        final QuranLineAlignment? alignment = _alignments[i];
        final Offset posInPainter =
            alignment?.inverse(Offset(localPos.dx, localPos.dy - yTop)) ??
            Offset(
              localPos.dx - ((_paintWidth - painter.width) / 2),
              localPos.dy - yTop,
            );

        final TextPosition textPos = painter.getPositionForOffset(posInPainter);
        final int offset = textPos.offset;
        final List<QuranWordMetadata> metadata = widget.painters[i].$2;
        for (final m in metadata) {
          if (offset >= m.startOffset && offset < m.endOffset) {
            return m;
          }
        }
        return null;
      }
    }
    return null;
  }
}

class _TextPictureCache {
  ui.Picture? picture;
  Size? size;
}

class _AllLinesPainter extends CustomPainter {
  _AllLinesPainter({
    required this.painters,
    required this.alignments,
    required this.yOffsets,
    required this.topInset,
    required this.pictureCache,
  });

  final List<(TextPainter, List<QuranWordMetadata>)> painters;
  final List<QuranLineAlignment?> alignments;
  final List<double> yOffsets;
  final double topInset;

  /// Mutable cache object passed from the state.
  final _TextPictureCache pictureCache;

  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch()..start();

    // Fast path: replay the cached Picture in a single GPU command.
    if (pictureCache.picture != null && pictureCache.size == size) {
      canvas.drawPicture(pictureCache.picture!);
      stopwatch.stop();
      logger.w(
        '[QuranFontsPerformance] Replayed cached picture in ${stopwatch.elapsedMilliseconds}ms (${stopwatch.elapsedMicroseconds}µs)',
      );
      return;
    }

    // Slow path (first paint): record all TextPainter draws into a Picture.
    final recorder = ui.PictureRecorder();
    final recordingCanvas = Canvas(recorder);

    for (var i = 0; i < painters.length; i++) {
      final TextPainter painter = painters[i].$1;
      final QuranLineAlignment? alignment = alignments[i];
      final double paintYOffset = yOffsets[i] - topInset;
      if (alignment != null && alignment.isValid) {
        recordingCanvas.save();
        recordingCanvas.translate(alignment.translateX, paintYOffset);
        recordingCanvas.scale(alignment.scaleX, 1);
        painter.paint(recordingCanvas, Offset.zero);
        recordingCanvas.restore();
      } else {
        final double dx = (size.width - painter.width) / 2;
        painter.paint(recordingCanvas, Offset(dx, paintYOffset));
      }

      if (_kDebugQuranLineGuides) {
        final double debugDx = alignment != null && alignment.isValid
            ? alignment.translateX
            : (size.width - painter.width) / 2;
        final lineRect = Rect.fromLTWH(
          0,
          paintYOffset,
          size.width,
          painter.height,
        );
        final fillPaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        final strokePaint = Paint()
          ..color = Colors.indigo.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final baselinePaint = Paint()
          ..color = Colors.red.withValues(alpha: 0.65)
          ..strokeWidth = 1;
        recordingCanvas.drawRect(lineRect, fillPaint);
        recordingCanvas.drawRect(lineRect, strokePaint);

        final List<LineMetrics> metrics = painter.computeLineMetrics();
        if (metrics.isNotEmpty) {
          final double baselineY = paintYOffset + metrics.first.baseline;
          recordingCanvas.drawLine(
            Offset(debugDx, baselineY),
            Offset(debugDx + painter.width, baselineY),
            baselinePaint,
          );
        }
      }
    }

    final ui.Picture picture = recorder.endRecording();

    // Replay the just-recorded picture into the real canvas.
    canvas.drawPicture(picture);

    // Cache the recorded picture globally via the mutable wrapper.
    pictureCache.picture = picture;
    pictureCache.size = size;

    stopwatch.stop();
    logger.w(
      '[QuranFontsPerformance] Recorded and painted lines in ${stopwatch.elapsedMilliseconds}ms (${stopwatch.elapsedMicroseconds}µs)',
    );
  }

  @override
  bool shouldRepaint(covariant _AllLinesPainter oldDelegate) {
    return !identical(oldDelegate.painters, painters) ||
        !identical(oldDelegate.alignments, alignments) ||
        oldDelegate.pictureCache != pictureCache;
  }
}
