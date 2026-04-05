import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/widgets/quran_line.dart';
import 'package:quran/src/widgets/quran_page_painter.dart';

void main() {
  testWidgets('QuranPagePainter performance test', (WidgetTester tester) async {
    // Create mock TextPainters
    final List<(TextPainter, List<QuranWordMetadata>)> painters = List.generate(
      15,
      (index) {
        final span = TextSpan(
          text: 'Word $index',
          style: const TextStyle(fontSize: 20),
        );
        final tp = TextPainter(text: span, textDirection: TextDirection.rtl);
        tp.layout();
        final metadata = <QuranWordMetadata>[];
        return (tp, metadata);
      },
    );

    final GlobalKey<State<StatefulWidget>> key = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          child: Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  // Trigger repaint without rebuilding QuranPagePainter
                  context.findRenderObject()!.markNeedsPaint();
                },
                child: QuranPagePainter(
                  key: key,
                  painters: painters,
                  lineSpacing: 10.0,
                ),
              );
            },
          ),
        ),
      ),
    );

    // Initial pump recorded the picture.
    final RenderObject renderObj = key.currentContext!.findRenderObject()!;

    // We can't easily see if it re-recorded, but we can measure time.
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      renderObj.markNeedsPaint();
      await tester.pump();
    }
    stopwatch.stop();
    print('1000 repaints took: ${stopwatch.elapsedMilliseconds} ms');
  });
}
