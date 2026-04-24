import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:quran_qcf/src/presentation/widgets/quran_page_painter.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QuranPagePainter timeline benchmark', (
    WidgetTester tester,
  ) async {
    final List<(TextPainter, List<QuranWordMetadata>)> painters = List.generate(
      15,
      (index) {
        final span = TextSpan(
          text: 'This is test word $index ' * 10,
          style: const TextStyle(fontSize: 24),
        );
        final tp = TextPainter(text: span, textDirection: TextDirection.rtl);
        tp.layout();
        return (tp, <QuranWordMetadata>[]);
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredBox(
          color: Colors.white,
          child: RepaintBoundary(
            child: QuranPagePainter(painters: painters, lineSpacing: 10.0),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder finder = find.byType(QuranPagePainter);

    await binding.traceAction(() async {
      for (var i = 0; i < 50; i++) {
        // Force repaint without rebuild
        tester.renderObject(finder).markNeedsPaint();
        await tester.pump();
      }
    }, reportKey: 'quran_page_painter_repaint');
  });
}
