import 'package:flutter/material.dart';

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
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
  });

  final TextPainter textPainter;
  final List<QuranWordMetadata> metadata;
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
          width: widget.textPainter.width,
          height: widget.textPainter.height,
          child: KeyedSubtree(
            key: _paintKey,
            child: CustomPaint(painter: _QuranLinePainter(widget.textPainter)),
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

    final TextPosition pos = widget.textPainter.getPositionForOffset(
      localPositionInParagraph,
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
  const _QuranLinePainter(this.textPainter);

  final TextPainter textPainter;

  @override
  void paint(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _QuranLinePainter oldDelegate) {
    return !identical(oldDelegate.textPainter, textPainter);
  }
}
