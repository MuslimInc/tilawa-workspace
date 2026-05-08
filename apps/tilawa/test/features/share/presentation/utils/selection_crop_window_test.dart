import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/share/presentation/utils/selection_crop_window.dart';

void main() {
  const metrics = QuranLayoutMetrics(
    fontSize: 20,
    fontHeight: 1,
    isScrollable: false,
    lineSpacing: 6,
  );

  group('selectedCropWindow', () {
    test('returns null when no text block contains the selection', () {
      final window = selectedCropWindow(
        [_textBlock(surah: 2, verse: 1)],
        metrics: metrics,
        surahNumber: 2,
        fromAyah: 2,
        toAyah: 3,
      );

      expect(window, isNull);
    });

    test('covers a single selected text block', () {
      final block = _textBlock(surah: 2, verse: 5);
      final window = selectedCropWindow(
        [block],
        metrics: metrics,
        surahNumber: 2,
        fromAyah: 5,
        toAyah: 5,
        diacriticSafetyInset: 0,
      );

      expect(window, isNotNull);
      expect(window!.top, 0);
      expect(window.bottom, block.painter.height);
      expect(window.height, block.painter.height);
    });

    test('spans multiple selected text blocks with line spacing', () {
      final first = _textBlock(surah: 2, verse: 4);
      final second = _textBlock(surah: 2, verse: 5);
      final third = _textBlock(surah: 2, verse: 6);
      final window = selectedCropWindow(
        [first, second, third],
        metrics: metrics,
        surahNumber: 2,
        fromAyah: 5,
        toAyah: 6,
        diacriticSafetyInset: 0,
      );

      final expectedTop = first.painter.height + metrics.lineSpacing;
      final expectedBottom =
          expectedTop +
          second.painter.height +
          metrics.lineSpacing +
          third.painter.height;

      expect(window, isNotNull);
      expect(window!.top, expectedTop);
      expect(window.bottom, expectedBottom);
      expect(window.height, expectedBottom - expectedTop);
    });

    test('applies diacritic safety inset without underflowing', () {
      final block = _textBlock(surah: 2, verse: 5);
      final window = selectedCropWindow(
        [const PreparedSpacerBlock(height: 10), block],
        metrics: metrics,
        surahNumber: 2,
        fromAyah: 5,
        toAyah: 5,
        diacriticSafetyInset: 20,
      );

      expect(window, isNotNull);
      expect(window!.top, 0);
      expect(window.bottom, 10 + block.painter.height);
      expect(window.height, 10 + block.painter.height);
    });
  });

  group('textBlockHasSelectedVerse', () {
    test('matches any selected metadata entry', () {
      final block = _textBlock(surah: 36, verse: 40);

      expect(
        textBlockHasSelectedVerse(
          block,
          surahNumber: 36,
          fromAyah: 36,
          toAyah: 40,
        ),
        isTrue,
      );
    });
  });
}

PreparedTextBlock _textBlock({required int surah, required int verse}) {
  final painter = TextPainter(
    text: const TextSpan(text: 'test', style: TextStyle(fontSize: 18)),
    textDirection: TextDirection.rtl,
  )..layout(maxWidth: 100);

  return PreparedTextBlock(
    painter: painter,
    metadata: [
      QuranWordMetadata(
        surah: surah,
        verse: verse,
        startOffset: 0,
        endOffset: 4,
      ),
    ],
  );
}
