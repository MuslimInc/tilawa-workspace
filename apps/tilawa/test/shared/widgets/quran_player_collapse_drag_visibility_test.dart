import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_animation_stability.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

bool _collapseBiased(double progress) => true;

void main() {
  group('Collapse drag — chrome visibility (white-screen regression)', () {
    test('footer collapse timeline has no full chrome gap', () {
      final List<double> timeline =
          QuranPlayerAnimationStability.simulateCollapseDragProgress(
        startProgress: 1,
        travelPixels: 692,
        steps: 60,
        dragPixelsPerStep: 8,
      );

      final List<double> gaps =
          QuranPlayerAnimationStability.findChromeVisibilityGaps(
        progressTimeline: timeline,
        miniPlayerHeight: 76,
        collapseBiasedAt: _collapseBiased,
        interactiveDrag: false,
      );

      expect(
        gaps,
        isEmpty,
        reason: 'footer collapse gaps at progress: $gaps',
      );
    });

    test('interactive collapse drag with anchor has no full chrome gap', () {
      final List<double> timeline =
          QuranPlayerAnimationStability.simulateCollapseDragProgress(
        startProgress: 1,
        travelPixels: 692,
        steps: 60,
        dragPixelsPerStep: 8,
      );

      final List<double> gaps =
          QuranPlayerAnimationStability.findChromeVisibilityGaps(
        progressTimeline: timeline,
        miniPlayerHeight: 76,
        collapseBiasedAt: _collapseBiased,
        interactiveCollapseAnchor: 1,
        interactiveDrag: true,
      );

      expect(
        gaps,
        isEmpty,
        reason: 'interactive collapse gaps at progress: $gaps',
      );
    });

    test('mid-collapse footer handoff keeps morph or mini visible', () {
      for (final double progress in <double>[0.25, 0.45, 0.65, 0.72]) {
        final PlayerExpandTransitionMetrics metrics =
            PlayerExpandTransitionMetrics.compute(
          progress: progress,
          miniPlayerHeight: 76,
          collapseBiased: true,
          heroHandoff: false,
        );
        expect(
          QuranPlayerAnimationStability.hasChromeVisibilityGap(metrics),
          isFalse,
          reason:
              'progress=$progress mini=${metrics.showMiniPlayer} '
              'sheet=${metrics.showExpandedSheet} '
              'morph=${metrics.showMorphLayer}',
        );
      }
    });

    test('late collapse drag still shows mini before sheet threshold', () {
      final PlayerExpandTransitionMetrics at70 =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.70,
        miniPlayerHeight: 76,
        collapseBiased: true,
        heroHandoff: false,
      );
      expect(at70.showMiniPlayer, isTrue);
      expect(at70.showExpandedSheet, isFalse);
      expect(at70.showMorphLayer, isTrue);
      expect(
        QuranPlayerAnimationStability.hasChromeVisibilityGap(at70),
        isFalse,
      );
    });

    test('settled collapsed shows mini only', () {
      final PlayerExpandTransitionMetrics settled =
          PlayerExpandTransitionMetrics.compute(
        progress: 0,
        miniPlayerHeight: 76,
        collapseBiased: true,
      );
      expect(settled.showMiniPlayer, isTrue);
      expect(settled.showExpandedSheet, isFalse);
      expect(settled.showMorphLayer, isFalse);
      expect(
        QuranPlayerAnimationStability.hasChromeVisibilityGap(settled),
        isFalse,
      );
    });

    test('settled expanded shows sheet at start of collapse', () {
      final PlayerExpandTransitionMetrics start =
          PlayerExpandTransitionMetrics.compute(
        progress: 1,
        miniPlayerHeight: 76,
        collapseBiased: true,
      );
      expect(start.showExpandedSheet, isTrue);
      expect(
        QuranPlayerAnimationStability.hasChromeVisibilityGap(start),
        isFalse,
      );
    });
  });

  group('Collapse drag — expand-forward vs collapse-biased mini timing', () {
    test('expand-forward hides mini mid-drag while collapse shows morph', () {
      const double progress = 0.70;
      final PlayerExpandTransitionMetrics expandForward =
          PlayerExpandTransitionMetrics.compute(
        progress: progress,
        miniPlayerHeight: 76,
        interactiveDrag: true,
        collapseBiased: false,
      );
      final PlayerExpandTransitionMetrics collapseDrag =
          PlayerExpandTransitionMetrics.compute(
        progress: progress,
        miniPlayerHeight: 76,
        interactiveDrag: true,
        collapseBiased: true,
        interactiveCollapseAnchor: 1,
      );

      expect(expandForward.showMiniPlayer, isFalse);
      expect(collapseDrag.showMiniPlayer, isFalse);
      expect(collapseDrag.showMorphLayer, isTrue);
      expect(
        QuranPlayerAnimationStability.hasChromeVisibilityGap(collapseDrag),
        isFalse,
      );
    });
  });
}
