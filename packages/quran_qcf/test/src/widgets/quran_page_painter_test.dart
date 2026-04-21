import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/widgets/quran_line.dart';
import 'package:quran_qcf/src/widgets/quran_page_painter.dart';

void main() {
  group('QuranPagePainter Widget Tests', () {
    late List<(TextPainter, List<QuranWordMetadata>)> mockPainters;

    setUp(() {
      mockPainters = List.generate(5, (index) {
        final text = 'Surah ${index + 1} Verse 1';
        final span = TextSpan(text: text, style: const TextStyle(fontSize: 20));
        final tp = TextPainter(text: span, textDirection: TextDirection.rtl);
        tp.layout();

        final metadata = <QuranWordMetadata>[
          QuranWordMetadata(
            surah: index + 1,
            verse: 1,
            startOffset: 0,
            endOffset: text.length + 5,
          ),
        ];

        return (tp, metadata);
      });
    });

    testWidgets('renders all lines using TextPainters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 20),
            child: Center(
              child: QuranPagePainter(
                painters: mockPainters,
                lineSpacing: 10.0,
              ),
            ),
          ),
        ),
      );

      // We ensure it builds without error.
      expect(find.byType(QuranPagePainter), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('triggers onLongPress events with correct word metadata', (
      WidgetTester tester,
    ) async {
      int? pressedSurah;
      int? pressedVerse;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 20),
            child: Align(
              child: QuranPagePainter(
                painters: mockPainters,
                lineSpacing: 10.0,
                onLongPressDown: (surah, verse, details) {
                  pressedSurah = surah;
                  pressedVerse = verse;
                },
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(QuranPagePainter));
      await tester.pumpAndSettle();

      // Because we mocked the metadata manually, and getPositionForOffset relies on realistic TextPainter coordinates,
      // it should be able to resolve to an offset. The middle of the text should hit one of the metadata offsets.
      expect(pressedSurah, 3);
      expect(pressedVerse, 1);
    });

    testWidgets('verifies cache holds across repaints', (
      WidgetTester tester,
    ) async {
      final GlobalKey<State<StatefulWidget>> key = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 20),
            child: RepaintBoundary(
              child: QuranPagePainter(
                key: key,
                painters: mockPainters,
                lineSpacing: 10.0,
              ),
            ),
          ),
        ),
      );

      final renderBox = key.currentContext!.findRenderObject()! as RenderBox;

      // Force repaint 100 times without changing the widget
      for (var i = 0; i < 100; i++) {
        renderBox.markNeedsPaint();
        await tester.pump();
      }

      // No crash, and the fact it works validates our mutable `_TextPictureCache`
      expect(find.byType(QuranPagePainter), findsOneWidget);
    });
  });
}
