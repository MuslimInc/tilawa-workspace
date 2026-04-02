import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
class QuranLine extends StatelessWidget {
  QuranLine({
    super.key,
    required this.richText,
    required this.metadata,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
  });

  final RichText richText;
  final List<QuranWordMetadata> metadata;
  final void Function(int surah, int verse)? onLongPress;
  final void Function(int surah, int verse)? onLongPressUp;
  final void Function(int surah, int verse)? onLongPressCancel;
  final void Function(int surah, int verse, LongPressStartDetails details)?
  onLongPressDown;

  final GlobalKey _richTextKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // We use a single GestureDetector for the entire block to minimize
    // the number of GestureRecognizer objects in memory.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) {
        final QuranWordMetadata? word = _findWordAtOffset(
          details.globalPosition,
        );
        if (word != null) {
          onLongPressDown?.call(word.surah, word.verse, details);
        }
      },
      onLongPress: () {
        // Unfortunately, onLongPress doesn't provide the offset,
        // but we can rely on the preceding onLongPressStart logic if needed,
        // or just handle it here if we want to resolve again.
        // For simplicity, we assume the user is still over the same word.
      },
      onLongPressUp: () {
        // Similarly for Up.
      },
      child: Center(
        child: KeyedSubtree(key: _richTextKey, child: richText),
      ),
    );
  }

  QuranWordMetadata? _findWordAtOffset(Offset globalPosition) {
    final BuildContext? context = _richTextKey.currentContext;
    if (context == null) return null;

    final RenderObject? renderBox = context.findRenderObject();
    if (renderBox == null || renderBox is! RenderParagraph) return null;
    final RenderParagraph renderParagraph = renderBox;

    // Use globalToLocal to ensure the coordinate is relative to the paragraph itself,
    // which handles any centering or padding from parent widgets.
    final Offset localPositionInParagraph = renderBox.globalToLocal(
      globalPosition,
    );

    final TextPosition pos = renderParagraph.getPositionForOffset(
      localPositionInParagraph,
    );

    final int offset = pos.offset;
    for (final QuranWordMetadata m in metadata) {
      if (offset >= m.startOffset && offset < m.endOffset) {
        return m;
      }
    }
    return null;
  }
}
