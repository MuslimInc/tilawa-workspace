import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'quran_line.dart';

/// Metadata for a single word within the consolidated page painter.
///
/// Extends [QuranWordMetadata] with the y-offset so the merged painter
/// can route hit-tests to the correct line's [TextPainter].
class PageWordMetadata {
  const PageWordMetadata({
    required this.lineIndex,
    required this.word,
    required this.yOffset,
  });

  final int lineIndex;
  final QuranWordMetadata word;
  final double yOffset;
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
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
  });

  /// Each entry: (textPainter, metadata) for one line.
  final List<(TextPainter, List<QuranWordMetadata>)> painters;
  final double lineSpacing;
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

  /// Maximum width across all painters.
  late double _maxWidth;

  /// Cached recorded [ui.Picture] from the first paint call.
  /// Subsequent frames replay this single GPU command instead of
  /// re-issuing ~15 individual [TextPainter.paint] calls.
  ui.Picture? _cachedPicture;
  Size? _cachedPictureSize;

  @override
  void initState() {
    super.initState();
    _computeLayout();
  }

  @override
  void didUpdateWidget(QuranPagePainter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.painters, widget.painters) ||
        oldWidget.lineSpacing != widget.lineSpacing) {
      _invalidatePictureCache();
      _computeLayout();
    }
  }

  @override
  void dispose() {
    _cachedPicture?.dispose();
    _cachedPicture = null;
    super.dispose();
  }

  void _invalidatePictureCache() {
    _cachedPicture?.dispose();
    _cachedPicture = null;
    _cachedPictureSize = null;
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
    _totalHeight = y;
    _maxWidth = maxW;
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
          width: _maxWidth,
          height: _totalHeight,
          child: KeyedSubtree(
            key: _paintKey,
            child: CustomPaint(
              painter: _AllLinesPainter(
                painters: widget.painters,
                yOffsets: _yOffsets,
                cachedPicture: _cachedPicture,
                cachedPictureSize: _cachedPictureSize,
                onPictureRecorded: _onPictureRecorded,
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
      final double yTop = _yOffsets[i];
      final TextPainter painter = widget.painters[i].$1;
      final double yBottom = yTop + painter.height;

      if (localPos.dy >= yTop && localPos.dy < yBottom) {
        // Center-aligned: offset x relative to this painter.
        final double painterX = (_maxWidth - painter.width) / 2;
        final posInPainter = Offset(localPos.dx - painterX, localPos.dy - yTop);

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

  /// Stores the [ui.Picture] recorded by [_AllLinesPainter] on its first
  /// paint call so subsequent frames replay a single GPU command.
  void _onPictureRecorded(ui.Picture picture, Size size) {
    _cachedPicture = picture;
    _cachedPictureSize = size;
  }
}

class _AllLinesPainter extends CustomPainter {
  _AllLinesPainter({
    required this.painters,
    required this.yOffsets,
    required this.cachedPicture,
    required this.cachedPictureSize,
    required this.onPictureRecorded,
  });

  final List<(TextPainter, List<QuranWordMetadata>)> painters;
  final List<double> yOffsets;

  /// Pre-recorded picture from a previous paint, owned by the State.
  final ui.Picture? cachedPicture;
  final Size? cachedPictureSize;

  /// Callback to hand the newly recorded picture back to the State.
  final void Function(ui.Picture picture, Size size) onPictureRecorded;

  @override
  void paint(Canvas canvas, Size size) {
    // Fast path: replay the cached Picture in a single GPU command.
    if (cachedPicture != null && cachedPictureSize == size) {
      canvas.drawPicture(cachedPicture!);
      return;
    }

    // Slow path (first paint): record all TextPainter draws into a Picture.
    final recorder = ui.PictureRecorder();
    final recordingCanvas = Canvas(recorder);

    for (var i = 0; i < painters.length; i++) {
      final TextPainter painter = painters[i].$1;
      final double dx = (size.width - painter.width) / 2;
      painter.paint(recordingCanvas, Offset(dx, yOffsets[i]));
    }

    final ui.Picture picture = recorder.endRecording();

    // Replay the just-recorded picture into the real canvas.
    canvas.drawPicture(picture);

    // Hand the picture to the State for caching — it owns the lifecycle.
    onPictureRecorded(picture, size);
  }

  @override
  bool shouldRepaint(covariant _AllLinesPainter oldDelegate) {
    return !identical(oldDelegate.painters, painters) ||
        oldDelegate.cachedPicture != cachedPicture;
  }
}
