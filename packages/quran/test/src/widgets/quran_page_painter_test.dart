import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/widgets/quran_line.dart';
import 'package:quran/src/widgets/quran_page_painter.dart';

/// Creates a simple [TextPainter] with a single word for testing.
(TextPainter, List<QuranWordMetadata>) _makePainterEntry(String text) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: const TextStyle(fontSize: 16)),
    textDirection: TextDirection.rtl,
  )..layout();
  return (
    tp,
    [
      QuranWordMetadata(
        surah: 1,
        verse: 1,
        startOffset: 0,
        endOffset: text.length,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranPagePainter', () {
    testWidgets('renders without errors with a single line', (
      WidgetTester tester,
    ) async {
      final (TextPainter, List<QuranWordMetadata>) entry = _makePainterEntry(
        'بسم الله',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPagePainter(painters: [entry], lineSpacing: 4.0),
          ),
        ),
      );

      expect(find.byType(QuranPagePainter), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders multiple lines', (WidgetTester tester) async {
      final List<(TextPainter, List<QuranWordMetadata>)> entries = [
        _makePainterEntry('line 1'),
        _makePainterEntry('line 2'),
        _makePainterEntry('line 3'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPagePainter(painters: entries, lineSpacing: 8.0),
          ),
        ),
      );

      expect(find.byType(QuranPagePainter), findsOneWidget);
    });

    testWidgets('repaints when painters list changes', (
      WidgetTester tester,
    ) async {
      final (TextPainter, List<QuranWordMetadata>) entry1 = _makePainterEntry(
        'old text',
      );
      final (TextPainter, List<QuranWordMetadata>) entry2 = _makePainterEntry(
        'new text',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPagePainter(painters: [entry1], lineSpacing: 4.0),
          ),
        ),
      );

      // Change painters.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPagePainter(painters: [entry2], lineSpacing: 4.0),
          ),
        ),
      );

      // Should not throw — cache invalidation on didUpdateWidget works.
      expect(find.byType(QuranPagePainter), findsOneWidget);
    });

    testWidgets('disposes cleanly', (WidgetTester tester) async {
      final (TextPainter, List<QuranWordMetadata>) entry = _makePainterEntry(
        'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPagePainter(painters: [entry], lineSpacing: 4.0),
          ),
        ),
      );

      // Remove widget — should dispose cached Picture without errors.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      expect(find.byType(QuranPagePainter), findsNothing);
    });
  });
}
