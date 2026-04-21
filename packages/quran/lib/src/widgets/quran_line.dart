import 'package:flutter/material.dart';

@immutable
class QuranLineVisualBounds {
  const QuranLineVisualBounds({required this.left, required this.right});

  final double left;
  final double right;

  double get width => right - left;

  QuranLineVisualBounds shift(double dx) {
    return QuranLineVisualBounds(left: left + dx, right: right + dx);
  }
}

@immutable
class QuranLineAlignment {
  const QuranLineAlignment({required this.source, required this.target});

  final QuranLineVisualBounds source;
  final QuranLineVisualBounds target;

  bool get isValid =>
      source.width.isFinite &&
      source.width > 0 &&
      target.width.isFinite &&
      target.width > 0;

  double get scaleX => isValid ? target.width / source.width : 1.0;

  double get translateX => isValid ? target.left - (source.left * scaleX) : 0.0;

  Offset inverse(Offset visualOffset) {
    if (!isValid) return visualOffset;
    return Offset((visualOffset.dx - translateX) / scaleX, visualOffset.dy);
  }
}

QuranLineVisualBounds? quranLineVisualBoundsFor(TextPainter painter) {
  final String text = painter.text?.toPlainText() ?? '';
  if (text.isEmpty) return null;

  final List<TextBox> boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  if (boxes.isEmpty) return null;

  double left = boxes.first.left;
  double right = boxes.first.right;
  for (final TextBox box in boxes.skip(1)) {
    if (box.left < left) left = box.left;
    if (box.right > right) right = box.right;
  }

  return QuranLineVisualBounds(left: left, right: right);
}

QuranLineVisualBounds? quranLineTargetBoundsFor(
  Iterable<QuranLineVisualBounds?> bounds,
) {
  final Iterator<QuranLineVisualBounds> iterator = bounds
      .whereType<QuranLineVisualBounds>()
      .iterator;
  if (!iterator.moveNext()) return null;

  double left = iterator.current.left;
  double right = iterator.current.right;
  while (iterator.moveNext()) {
    final QuranLineVisualBounds current = iterator.current;
    if (current.left < left) left = current.left;
    if (current.right > right) right = current.right;
  }

  return QuranLineVisualBounds(left: left, right: right);
}

/// Metadata for a single word within a Quran line block.
class QuranWordMetadata {
  const QuranWordMetadata({
    required this.surah,
    required this.verse,
    required this.startOffset,
    required this.endOffset,
  });

  /// The surah number (1-114).
  final int surah;

  /// The verse number (1-indexed).
  final int verse;

  /// The start character offset in the parent TextSpan.
  final int startOffset;

  /// The end character offset (exclusive) in the parent TextSpan.
  final int endOffset;
}

/// A widget that renders a block of Quran text and handles word-level gestures
/// without individual recognizer objects for every word.
class QuranLine extends StatefulWidget {
  const QuranLine({
    super.key,
    required this.textPainter,
    required this.metadata,
    this.width,
    this.alignment,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
  });

  final TextPainter textPainter;
  final List<QuranWordMetadata> metadata;
  final double? width;
  final QuranLineAlignment? alignment;
  final void Function(int surah, int verse)? onLongPress;
  final void Function(int surah, int verse)? onLongPressUp;
  final void Function(int surah, int verse)? onLongPressCancel;
  final void Function(int surah, int verse, LongPressStartDetails details)?
  onLongPressDown;

  @override
  State<QuranLine> createState() => _QuranLineState();
}

class _QuranLineState extends State<QuranLine> {
  // Survives widget rebuilds — created once per element lifecycle, not per
  // QuranLine instantiation. This prevents GlobalKey registry churn when
  // _cachedLineWidgets is invalidated and the list is rebuilt.
  final GlobalKey _paintKey = GlobalKey();
  QuranWordMetadata? _activeWord;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) {
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
          width: widget.width ?? widget.textPainter.width,
          height: widget.textPainter.height,
          child: KeyedSubtree(
            key: _paintKey,
            child: CustomPaint(
              painter: _QuranLinePainter(widget.textPainter, widget.alignment),
            ),
          ),
        ),
      ),
    );
  }

  QuranWordMetadata? _findWordAtOffset(Offset globalPosition) {
    final BuildContext? ctx = _paintKey.currentContext;
    if (ctx == null) return null;

    final RenderObject? renderBox = ctx.findRenderObject();
    if (renderBox == null || renderBox is! RenderBox) return null;

    final Offset localPositionInParagraph = renderBox.globalToLocal(
      globalPosition,
    );
    final Offset textPosition =
        widget.alignment?.inverse(localPositionInParagraph) ??
        localPositionInParagraph;

    final TextPosition pos = widget.textPainter.getPositionForOffset(
      textPosition,
    );

    final int offset = pos.offset;
    for (final QuranWordMetadata m in widget.metadata) {
      if (offset >= m.startOffset && offset < m.endOffset) {
        return m;
      }
    }
    return null;
  }
}

class _QuranLinePainter extends CustomPainter {
  const _QuranLinePainter(this.textPainter, this.alignment);

  final TextPainter textPainter;
  final QuranLineAlignment? alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final QuranLineAlignment? lineAlignment = alignment;
    if (lineAlignment != null && lineAlignment.isValid) {
      canvas.save();
      canvas.translate(lineAlignment.translateX, 0);
      canvas.scale(lineAlignment.scaleX, 1);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
      return;
    }

    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _QuranLinePainter oldDelegate) {
    return !identical(oldDelegate.textPainter, textPainter) ||
        oldDelegate.alignment != alignment;
  }
}
