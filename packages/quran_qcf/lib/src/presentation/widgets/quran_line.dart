import 'package:flutter/material.dart';

import '../../domain/models/quran_word_metadata.dart';
import '../layout/quran_line_layout.dart';

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
