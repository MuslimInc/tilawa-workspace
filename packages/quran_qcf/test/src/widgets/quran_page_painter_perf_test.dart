// ignore_for_file: avoid_print — manual perf diagnostics

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:quran_qcf/src/presentation/widgets/quran_page_painter.dart';

void main() {
  testWidgets('QuranPagePainter Performance: Repaint Frame Cost', (
    WidgetTester tester,
  ) async {
    final List<(TextPainter, List<QuranWordMetadata>)> painters = List.generate(
      15,
      (index) {
        final span = TextSpan(
          text: 'Word $index ' * 10,
          style: const TextStyle(fontSize: 20),
        );
        final tp = TextPainter(text: span, textDirection: TextDirection.rtl);
        tp.layout();
        return (tp, <QuranWordMetadata>[]);
      },
    );

    final GlobalKey<State<StatefulWidget>> key = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          child: Builder(
            builder: (context) {
              return QuranPagePainter(
                key: key,
                painters: painters,
                lineSpacing: 10.0,
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final RenderObject renderObj = key.currentContext!.findRenderObject()!;

    // Warmup
    for (var i = 0; i < 10; i++) {
      renderObj.markNeedsPaint();
      await tester.pump();
    }

    // Benchmark over 1000 aggressive repaint frames
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      renderObj.markNeedsPaint();
      await tester.pump();
    }
    stopwatch.stop();

    final int elapsed = stopwatch.elapsedMilliseconds;
    final double costPerFrame = elapsed / 1000.0;

    print('=====================================');
    print('QuranPagePainter Repaint Benchmark');
    print('Total Time (1000 repaints): ${elapsed}ms');
    print('Average Time Per Frame Build: ${costPerFrame.toStringAsFixed(3)}ms');
    print('Target: 16.6ms (60 FPS) / 8.3ms (120 FPS)');
    print('=====================================');

    // Due to the _TextPictureCache optimization, measuring time for 1000 frames using the `drawPicture` call
    // is highly efficient and avoids re-recording the Display List operations.
    expect(
      costPerFrame,
      lessThan(8.0),
      reason:
          'Repaint frame cost is too high, jank detected. Average frame cost $costPerFrame ms.',
    );
  });
}
