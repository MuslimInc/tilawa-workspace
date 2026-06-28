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
    return ColoredBox(
      color: pageBackgroundColor,
      child: Center(
        child: Text(
          '$surahNumber:${pageSpec.pageNumber}:${pageSpec.fromAyah}-${pageSpec.toAyah}:$isCapturing',
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }
}

Widget _buildSubject(
  VideoCompositionSpec spec, {
  MushafPageRenderer pageRenderer = const _FakeMushafPageRenderer(),
}) {
  return MaterialApp(
    theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
    home: Scaffold(
      body: Center(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: VideoComposition(spec: spec, pageRenderer: pageRenderer),
        ),
      ),
    ),
  );
}

void main() {
  const pageSpec = VideoPageSpec(
    pageNumber: 3,
    fromAyah: 6,
    toAyah: 8,
    isInitialSelection: true,
  );

  test('VideoCompositionSpec is value-equatable for stable rebuilds', () {
    final first = VideoCompositionSpec(
      surahNumber: 2,
      pageSpec: pageSpec,
      pageIndex: 0,
      totalPages: 2,
      reciterName: 'Test Reciter',
      mode: VideoCompositionMode.capture,
      localeName: 'ar',
      backgroundColor: const Color(0xFFFFF8ED),
    );
    final second = VideoCompositionSpec(
      surahNumber: 2,
      pageSpec: pageSpec,
      pageIndex: 0,
      totalPages: 2,
      reciterName: 'Test Reciter',
      mode: VideoCompositionMode.capture,
      localeName: 'ar',
      backgroundColor: const Color(0xFFFFF8ED),
    );

    expect(first, equals(second));
    expect(first.canvasWidth, reelCanvasWidth);
    expect(first.canvasHeight, reelCanvasHeight);
    expect(first.surahHeaderDecision.includeBanner, isTrue);
    expect(first.surahHeaderDecision.includeBismillah, isTrue);
  });

  testWidgets('renders an intrinsic 1080x1920 canvas', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _buildSubject(VideoCompositionSpec(surahNumber: 2, pageSpec: pageSpec)),
    );

    expect(
      tester.getSize(find.byKey(VideoComposition.canvasKey)),
      const Size(reelCanvasWidth, reelCanvasHeight),
    );
  });

  testWidgets('shows safe-zone guides in edit mode', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _buildSubject(
        VideoCompositionSpec(
          surahNumber: 2,
          pageSpec: pageSpec,
          mode: VideoCompositionMode.edit,
        ),
      ),
    );

    expect(find.byKey(VideoComposition.safeZoneGuidesKey), findsOneWidget);
  });

  testWidgets('hides safe-zone guides outside edit mode', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _buildSubject(
        VideoCompositionSpec(
          surahNumber: 2,
          pageSpec: pageSpec,
          mode: VideoCompositionMode.capture,
        ),
      ),
    );
    expect(find.byKey(VideoComposition.safeZoneGuidesKey), findsNothing);

    await tester.pumpWidget(
      _buildSubject(
        VideoCompositionSpec(
          surahNumber: 2,
          pageSpec: pageSpec,
          mode: VideoCompositionMode.review,
        ),
      ),
    );
    expect(find.byKey(VideoComposition.safeZoneGuidesKey), findsNothing);
  });
}
