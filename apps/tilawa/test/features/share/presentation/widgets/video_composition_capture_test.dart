import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/utils/video_page_specs.dart';
import 'package:tilawa/features/share/presentation/widgets/mushaf_page_renderer.dart';
import 'package:tilawa/features/share/presentation/widgets/video_composition.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _FakeMushafPageRenderer extends MushafPageRenderer {
  const _FakeMushafPageRenderer();

  @override
  Widget build({
    required BuildContext context,
    required VideoPageSpec pageSpec,
    required int surahNumber,
    required Color? Function(int surah, int verse) verseBackgroundColor,
    required Color? Function(int surah, int verse) verseTextColor,
    required Color textColor,
    required Color pageBackgroundColor,
    bool isCapturing = false,
  }) {
    return ColoredBox(color: pageBackgroundColor);
  }
}

void main() {
  testWidgets('capture boundary contains VideoComposition without FittedBox', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    const pageSpec = VideoPageSpec(pageNumber: 3, fromAyah: 6, toAyah: 8);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: VideoComposition(
              pageRenderer: const _FakeMushafPageRenderer(),
              spec: VideoCompositionSpec(
                surahNumber: 2,
                pageSpec: pageSpec,
                mode: VideoCompositionMode.capture,
              ),
            ),
          ),
        ),
      ),
    );

    final boundaryFinder = find.byKey(boundaryKey);
    expect(
      find.descendant(of: boundaryFinder, matching: find.byType(FittedBox)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: boundaryFinder,
        matching: find.byType(VideoComposition),
      ),
      findsOneWidget,
    );
  });
}
