import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_semantics_ids.dart';
import 'package:tilawa/shared/widgets/quran_player_animation_stability.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layer.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layout.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'quran_player_mini_bar_layout_expectations.dart';

const AudioEntity _testAudio = AudioEntity(
  id: '1',
  title: 'Al-Fatiha',
  url: 'https://example.com/001.mp3',
  duration: Duration(minutes: 1),
  artist: 'Test Reciter',
);

const Rect _miniBarRect = Rect.fromLTWH(16, 620, 368, 76);

QuranPlayerMorphThemeGeometry _testGeometry() {
  final barTokens = TilawaMediaPlayerBarTokens.defaults();
  return QuranPlayerMorphThemeGeometry.fromBarTokens(
    spaceLarge: 16,
    progressHeight: 3,
    barContentPadding: barTokens.contentPadding,
    barTokens: barTokens,
    expandedArtBorderRadius: 16,
  );
}

/// Progress samples along a footer collapse drag (high → low).
List<double> _collapseDragProgressSamples() {
  return QuranPlayerAnimationStability.simulateCollapseDragProgress(
    startProgress: 1,
    travelPixels: 692,
    steps: 12,
    dragPixelsPerStep: 28,
  );
}

void main() {
  group('Collapse drag — morph visibility window', () {
    test('mid-collapse drag keeps morph layer active', () {
      for (final double progress in <double>[0.35, 0.50, 0.65]) {
        final PlayerExpandTransitionMetrics metrics =
            PlayerExpandTransitionMetrics.compute(
              progress: progress,
              miniPlayerHeight: 76,
              collapseBiased: true,
            );
        expect(
          metrics.showMorphLayer,
          isTrue,
          reason: 'progress=$progress',
        );
        expect(
          metrics.handoffT,
          greaterThan(0.02),
          reason: 'progress=$progress',
        );
      }
    });

    test('interactive collapse drag with anchor keeps morph mid-gesture', () {
      for (final double progress in <double>[0.35, 0.50, 0.65]) {
        final PlayerExpandTransitionMetrics metrics =
            PlayerExpandTransitionMetrics.compute(
              progress: progress,
              miniPlayerHeight: 76,
              collapseBiased: true,
              interactiveDrag: true,
              interactiveCollapseAnchor: 1,
            );
        expect(
          metrics.showMorphLayer,
          isTrue,
          reason: 'progress=$progress handoff=${metrics.handoffT}',
        );
      }
    });

    test('simulated collapse drag samples keep morph through handoff', () {
      for (final double progress in _collapseDragProgressSamples()) {
        if (progress < 0.12 || progress > 0.92) {
          continue;
        }
        final PlayerExpandTransitionMetrics metrics =
            PlayerExpandTransitionMetrics.compute(
              progress: progress,
              miniPlayerHeight: 76,
              collapseBiased: true,
            );
        expect(
          metrics.showMorphLayer,
          isTrue,
          reason: 'progress=$progress handoff=${metrics.handoffT}',
        );
      }
    });
  });

  group('Collapse drag — morph mini anchor vs media bar (LTR)', () {
    late QuranPlayerMorphThemeGeometry geometry;

    setUp(() {
      geometry = _testGeometry();
    });

    test('progress 0 art matches bar artwork slot', () {
      final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      expect(
        layout.artRect,
        quranPlayerExpectedMiniArtRect(
          miniBarRect: _miniBarRect,
          geometry: geometry,
          textDirection: TextDirection.ltr,
        ),
      );
    });

    test('progress 0 title sits trailing of artwork', () {
      final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      final Rect expectedTitle = quranPlayerExpectedMiniTitleRect(
        miniBarRect: _miniBarRect,
        miniArt: layout.artRect,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      expect(layout.titleRect.left, closeTo(expectedTitle.left, 0.5));
      expect(layout.titleRect.right, closeTo(expectedTitle.right, 0.5));
      expect(layout.titleScaleAlignment, Alignment.topLeft);
    });

    test('collapse drag keeps metadata beside art not stacked below', () {
      for (final double progress in <double>[0.12, 0.25, 0.38]) {
        final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
          progress: progress,
          viewport: const Size(400, 800),
          miniBarRect: _miniBarRect,
          sheetOffsetY: 100,
          geometry: geometry,
          textDirection: TextDirection.ltr,
        );
        expect(
          layout.horizontalIdentity,
          isTrue,
          reason: 'progress=$progress',
        );
        expect(
          layout.metadataIsVerticallyStacked,
          isFalse,
          reason: 'progress=$progress',
        );
      }
    });

    test('mid-drag art stays between mini and expanded anchors', () {
      const double progress = 0.42;
      final QuranPlayerMorphLayout mid = QuranPlayerMorphLayout.compute(
        progress: progress,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 180,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      final Rect miniArt = quranPlayerExpectedMiniArtRect(
        miniBarRect: _miniBarRect,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      final QuranPlayerMorphLayout expanded = QuranPlayerMorphLayout.compute(
        progress: 1,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 180,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      expect(
        mid.artRect.width,
        inInclusiveRange(miniArt.width, expanded.artRect.width),
      );
      expect(
        mid.artRect.center.dy,
        lessThan(miniArt.center.dy),
      );
    });
  });

  group('Collapse drag — morph mini anchor vs media bar (RTL)', () {
    late QuranPlayerMorphThemeGeometry geometry;

    setUp(() {
      geometry = _testGeometry();
    });

    test('progress 0 art matches trailing artwork slot', () {
      final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.rtl,
      );
      final Rect expected = quranPlayerExpectedMiniArtRect(
        miniBarRect: _miniBarRect,
        geometry: geometry,
        textDirection: TextDirection.rtl,
      );
      expect(layout.artRect, expected);
      expect(
        layout.artRect.right,
        closeTo(_miniBarRect.right - 16 - 12, 1),
      );
    });

    test('progress 0 title sits leading of artwork', () {
      final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.rtl,
      );
      expect(layout.titleRect.right, lessThanOrEqualTo(layout.artRect.left));
      expect(layout.titleScaleAlignment, Alignment.topRight);
    });

    test('collapse drag samples keep RTL mini anchor at low progress', () {
      for (final double progress in _collapseDragProgressSamples()) {
        if (progress > 0.35) {
          continue;
        }
        final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
          progress: progress,
          viewport: const Size(400, 800),
          miniBarRect: _miniBarRect,
          sheetOffsetY: 0,
          geometry: geometry,
          textDirection: TextDirection.rtl,
        );
        final Rect expected = quranPlayerExpectedMiniArtRect(
          miniBarRect: _miniBarRect,
          geometry: geometry,
          textDirection: TextDirection.rtl,
        );
        expect(
          layout.artRect.right,
          closeTo(expected.right, 2 + progress * 40),
          reason: 'progress=$progress',
        );
      }
    });

    test('RTL morph art is not mirrored to LTR leading edge at progress 0', () {
      final QuranPlayerMorphLayout rtl = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.rtl,
      );
      final QuranPlayerMorphLayout ltr = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      expect(rtl.artRect.left, greaterThan(ltr.artRect.left + 100));
    });
  });

  group('Collapse drag — morph layer vs mini bar widget (RTL)', () {
    testWidgets('morph artwork aligns with bar artwork at collapse start', (
      tester,
    ) async {
      const double barWidth = 368;
      const Key artworkKey = Key('test_mini_artwork');
      final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: _miniBarRect,
        sheetOffsetY: 0,
        geometry: _testGeometry(),
        textDirection: TextDirection.rtl,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: const Color(0xFF2E7D6F),
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: SizedBox(
            width: 400,
            height: 800,
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: _miniBarRect,
                  child: TilawaMediaPlayerBar(
                    layoutWidth: barWidth,
                    title: _testAudio.title,
                    subtitle: _testAudio.artist,
                    progress: 0.2,
                    isPlaying: false,
                    canGoPrevious: true,
                    canGoNext: true,
                    artwork: const SizedBox(
                      key: artworkKey,
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: QuranPlayerMorphLayer(
                    audio: _testAudio,
                    handoffT: 0.55,
                    layout: layout,
                    onImageBackdrop: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final Rect barArt = tester.getRect(find.byKey(artworkKey));
      final Rect morphArt = tester.getRect(
        find.descendant(
          of: find.byType(QuranPlayerMorphLayer),
          matching: find.bySemanticsIdentifier(
            QuranPlayerSemanticsIds.expandedArtwork,
          ),
        ),
      );

      // Bar row gaps can differ slightly from morph theme geometry; keep
      // trailing edges aligned within one compact artwork inset.
      expect(barArt.width, closeTo(morphArt.width, 8));
      expect((barArt.right - morphArt.right).abs(), lessThan(18));
      expect(morphArt.right, closeTo(layout.artRect.right, 1));
    });
  });
}
