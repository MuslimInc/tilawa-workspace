import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/share/presentation/utils/selected_quran_range_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const metrics = QuranLayoutMetrics(
    fontSize: 20,
    fontHeight: 1,
    isScrollable: false,
    padding: EdgeInsets.fromLTRB(12, 90, 12, 90),
    lineSpacing: 6,
    bismillahHeight: 28.8,
  );

  const viewportSize = Size(360, 520);

  group('buildSelectedQuranRangeComposition', () {
    test('prepends header and Bismillah for normal surahs', () {
      final selectedBlock = _textBlock(surah: 18, verse: 2);
      final composition = buildSelectedQuranRangeComposition(
        sourcePage: PreparedQuranPage(
          metrics: metrics,
          blocks: [_textBlock(surah: 18, verse: 1), selectedBlock],
        ),
        surahNumber: 18,
        fromAyah: 2,
        toAyah: 2,
        viewportSize: viewportSize,
      );

      expect(composition, isNotNull);
      expect(composition!.page.blocks.first, isA<PreparedHeaderBlock>());
      expect(
        composition.page.blocks.whereType<PreparedBismillahBlock>(),
        hasLength(1),
      );
      expect(composition.page.blocks.whereType<PreparedTextBlock>().toList(), [
        selectedBlock,
      ]);
      expect(composition.estimatedHeight, lessThan(viewportSize.height));
    });

    test('omits Bismillah for Al-Fatihah and At-Tawbah', () {
      for (final surahNumber in [1, 9]) {
        final composition = buildSelectedQuranRangeComposition(
          sourcePage: PreparedQuranPage(
            metrics: metrics,
            blocks: [_textBlock(surah: surahNumber, verse: 1)],
          ),
          surahNumber: surahNumber,
          fromAyah: 1,
          toAyah: 1,
          viewportSize: viewportSize,
        );

        expect(composition, isNotNull);
        expect(
          composition!.page.blocks.whereType<PreparedHeaderBlock>(),
          hasLength(1),
        );
        expect(
          composition.page.blocks.whereType<PreparedBismillahBlock>(),
          isEmpty,
        );
      }
    });

    test('resets source page vertical padding for top-composed output', () {
      final composition = buildSelectedQuranRangeComposition(
        sourcePage: PreparedQuranPage(
          metrics: metrics,
          blocks: [_textBlock(surah: 2, verse: 255)],
        ),
        surahNumber: 2,
        fromAyah: 255,
        toAyah: 255,
        viewportSize: viewportSize,
      );

      expect(composition, isNotNull);
      expect(composition!.page.metrics.padding.left, metrics.padding.left);
      expect(composition.page.metrics.padding.right, metrics.padding.right);
      expect(composition.page.metrics.padding.top, lessThan(20));
      expect(composition.page.metrics.padding.bottom, lessThan(20));
    });

    test(
      'returns null when no prepared text block intersects the selection',
      () {
        final composition = buildSelectedQuranRangeComposition(
          sourcePage: PreparedQuranPage(
            metrics: metrics,
            blocks: [_textBlock(surah: 36, verse: 10)],
          ),
          surahNumber: 36,
          fromAyah: 20,
          toAyah: 22,
          viewportSize: viewportSize,
        );

        expect(composition, isNull);
      },
    );
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
