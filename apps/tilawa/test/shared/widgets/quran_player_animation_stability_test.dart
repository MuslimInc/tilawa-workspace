import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_animation_stability.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

/// Mirrors [_collapseBiasedMetrics] in [QuranPlayerWidget].
bool collapseBiasedAt({
  required double progress,
  required double dragStartProgress,
  bool isCollapsing = false,
}) {
  if (isCollapsing) {
    return true;
  }
  return progress < dragStartProgress - 0.001;
}

void main() {
  group('QuranPlayerAnimationStability — drag progress', () {
    test('collapse drag progress is monotonic decreasing', () {
      final List<double> timeline =
          QuranPlayerAnimationStability.simulateCollapseDragProgress(
            startProgress: 1,
            travelPixels: 692,
            steps: 40,
            dragPixelsPerStep: 18,
          );

      expect(
        QuranPlayerAnimationStability.isMonotonicDecreasing(timeline),
        isTrue,
        reason: timeline.toString(),
      );
    });
  });

  group('QuranPlayerAnimationStability — metric timeline (qp_lag audit)', () {
    test(
      'collapse drag from 1.0 has no metric jumps above threshold',
      () {
        const double dragStart = 1.0;
        const double travel = 692;
        final List<double> timeline =
            QuranPlayerAnimationStability.simulateCollapseDragProgress(
              startProgress: dragStart,
              travelPixels: travel,
              steps: 50,
              dragPixelsPerStep: 10,
            );

        final List<MetricJump> jumps =
            QuranPlayerAnimationStability.findMetricJumps(
              progressTimeline: timeline,
              miniPlayerHeight: 76,
              collapseBiasedAt: (double p) => collapseBiasedAt(
                progress: p,
                dragStartProgress: dragStart,
              ),
              interactiveCollapseAnchor: dragStart,
            );

        expect(
          jumps,
          isEmpty,
          reason: jumps.map((MetricJump j) => j.toString()).join('\n'),
        );
      },
    );

    test(
      'collapse from 0.85 mid-expanded drag has no metric jumps',
      () {
        const double dragStart = 0.85;
        const double travel = 692;
        final List<double> timeline =
            QuranPlayerAnimationStability.simulateCollapseDragProgress(
              startProgress: dragStart,
              travelPixels: travel,
              steps: 30,
              dragPixelsPerStep: 16,
            );

        final List<MetricJump> jumps =
            QuranPlayerAnimationStability.findMetricJumps(
              progressTimeline: timeline,
              miniPlayerHeight: 76,
              collapseBiasedAt: (double p) => collapseBiasedAt(
                progress: p,
                dragStartProgress: dragStart,
              ),
              interactiveCollapseAnchor: dragStart,
            );

        expect(jumps, isEmpty);
      },
    );

    test('sheetMotionT protects high-expanded band then tracks drag', () {
      const double dragStart = 1.0;
      final List<double> timeline =
          QuranPlayerAnimationStability.simulateCollapseDragProgress(
            startProgress: dragStart,
            travelPixels: 692,
            steps: 10,
            dragPixelsPerStep: 30,
          );

      for (final double progress in timeline) {
        final PlayerExpandTransitionMetrics metrics =
            PlayerExpandTransitionMetrics.compute(
              progress: progress,
              miniPlayerHeight: 76,
              interactiveDrag: true,
              collapseBiased: collapseBiasedAt(
                progress: progress,
                dragStartProgress: dragStart,
              ),
              interactiveCollapseAnchor: dragStart,
            );
        if (progress >= 0.90) {
          expect(metrics.sheetMotionT, 1, reason: 'progress=$progress');
        } else {
          expect(
            metrics.sheetMotionT,
            closeTo(progress, 0.02),
            reason: 'progress=$progress',
          );
        }
      }
    });
  });

  group('QuranPlayerAnimationStability — helpers', () {
    test('isMonotonicDecreasing rejects increasing timeline', () {
      expect(
        QuranPlayerAnimationStability.isMonotonicDecreasing(
          <double>[0.4, 0.5],
        ),
        isFalse,
      );
    });

    test('hasChromeVisibilityGap detects fully hidden chrome', () {
      const PlayerExpandTransitionMetrics gap = PlayerExpandTransitionMetrics(
        miniOpacity: 0,
        expandedOpacity: 0,
        handoffT: 0,
        stageChromeOpacity: 0,
        miniIdentityOpacity: 0,
        sheetPresentationOpacity: 0,
        backdropOpacity: 0,
        scrimOpacity: 0,
        miniSlideY: 0,
        sheetMotionT: 0.5,
        queueChromeT: 0,
        showMiniPlayer: false,
        showExpandedSheet: false,
        showMorphLayer: false,
      );
      expect(
        QuranPlayerAnimationStability.hasChromeVisibilityGap(gap),
        isTrue,
      );
    });

    test('findMetricJumps reports large step discontinuities', () {
      final List<MetricJump> jumps =
          QuranPlayerAnimationStability.findMetricJumps(
            progressTimeline: <double>[1, 0],
            miniPlayerHeight: 76,
            collapseBiasedAt: (_) => true,
            interactiveCollapseAnchor: 1,
          );
      expect(jumps, isNotEmpty);
      expect(jumps.first.toString(), contains('MetricJump'));
    });

    test('findChromeVisibilityGaps with non-interactive collapse', () {
      final List<double> gaps =
          QuranPlayerAnimationStability.findChromeVisibilityGaps(
            progressTimeline: <double>[0, 1],
            miniPlayerHeight: 76,
            collapseBiasedAt: (_) => true,
            interactiveDrag: false,
          );
      expect(gaps, isEmpty);
    });
  });

  group('QuranPlayerAnimationStability — chrome visibility', () {
    test('simulated interactive collapse has no visibility gaps', () {
      const double dragStart = 1;
      final List<double> timeline =
          QuranPlayerAnimationStability.simulateCollapseDragProgress(
            startProgress: dragStart,
            travelPixels: 692,
            steps: 40,
            dragPixelsPerStep: 12,
          );

      final List<double> gaps =
          QuranPlayerAnimationStability.findChromeVisibilityGaps(
            progressTimeline: timeline,
            miniPlayerHeight: 76,
            collapseBiasedAt: (double p) => p < dragStart - 0.001,
            interactiveCollapseAnchor: dragStart,
          );

      expect(gaps, isEmpty, reason: 'gaps at $gaps');
    });
  });

  group('PlayerExpandTransitionMetrics — path continuity', () {
    test('flip at collapse anchor does not jump miniOpacity', () {
      const double anchor = 0.95;
      final PlayerExpandTransitionMetrics before =
          PlayerExpandTransitionMetrics.compute(
            progress: anchor,
            miniPlayerHeight: 76,
            interactiveDrag: true,
            collapseBiased: false,
            interactiveCollapseAnchor: anchor,
          );
      final PlayerExpandTransitionMetrics after =
          PlayerExpandTransitionMetrics.compute(
            progress: anchor - 0.002,
            miniPlayerHeight: 76,
            interactiveDrag: true,
            collapseBiased: true,
            interactiveCollapseAnchor: anchor,
          );

      expect(
        (after.miniOpacity - before.miniOpacity).abs(),
        lessThan(QuranPlayerAnimationStability.maxMetricStepDelta),
      );
    });
  });
}
