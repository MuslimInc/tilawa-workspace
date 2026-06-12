import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

/// Audit helpers for expand/collapse animation stability (video / jank regressions).
abstract final class QuranPlayerAnimationStability {
  QuranPlayerAnimationStability._();

  /// Maximum allowed per-step change in a normalized metric during drag.
  static const double maxMetricStepDelta = 0.18;

  /// Simulates shell footer collapse drag from [startProgress] toward 0.
  static List<double> simulateCollapseDragProgress({
    required double startProgress,
    required double travelPixels,
    required int steps,
    double dragPixelsPerStep = 24,
  }) {
    double progress = startProgress;
    final List<double> timeline = <double>[progress];
    for (int i = 0; i < steps; i++) {
      progress = QuranPlayerExpandPhysics.applyDragDelta(
        current: progress,
        dragPixels: dragPixelsPerStep,
        travelPixels: travelPixels,
      );
      timeline.add(progress);
    }
    return timeline;
  }

  /// Returns metric discontinuities above [maxMetricStepDelta] on a timeline.
  static List<MetricJump> findMetricJumps({
    required List<double> progressTimeline,
    required double miniPlayerHeight,
    required bool Function(double progress) collapseBiasedAt,
    double? interactiveCollapseAnchor,
  }) {
    PlayerExpandTransitionMetrics? previous;
    final List<MetricJump> jumps = <MetricJump>[];

    for (final double progress in progressTimeline) {
      final PlayerExpandTransitionMetrics metrics =
          PlayerExpandTransitionMetrics.compute(
            progress: progress,
            miniPlayerHeight: miniPlayerHeight,
            interactiveDrag: true,
            collapseBiased: collapseBiasedAt(progress),
            interactiveCollapseAnchor: interactiveCollapseAnchor,
          );

      if (previous != null) {
        void check(String name, double before, double after) {
          final double delta = (after - before).abs();
          if (delta > maxMetricStepDelta) {
            jumps.add(
              MetricJump(
                progress: progress,
                metric: name,
                delta: delta,
                before: before,
                after: after,
              ),
            );
          }
        }

        check('miniOpacity', previous.miniOpacity, metrics.miniOpacity);
        check(
          'sheetPresentationOpacity',
          previous.sheetPresentationOpacity,
          metrics.sheetPresentationOpacity,
        );
        check(
          'stageChromeOpacity',
          previous.stageChromeOpacity,
          metrics.stageChromeOpacity,
        );
        check('handoffT', previous.handoffT, metrics.handoffT);
        // Visibility flags may flip once; opacity jumps are the jank signal.
      }
      previous = metrics;
    }
    return jumps;
  }

  /// True when no mini, expanded sheet, or morph chrome is visible.
  static bool hasChromeVisibilityGap(PlayerExpandTransitionMetrics metrics) {
    return !metrics.showMiniPlayer &&
        !metrics.showExpandedSheet &&
        !metrics.showMorphLayer;
  }

  /// Progress values on [progressTimeline] where chrome fully disappears.
  static List<double> findChromeVisibilityGaps({
    required List<double> progressTimeline,
    required double miniPlayerHeight,
    required bool Function(double progress) collapseBiasedAt,
    double? interactiveCollapseAnchor,
    bool interactiveDrag = true,
  }) {
    final List<double> gaps = <double>[];
    for (final double progress in progressTimeline) {
      final PlayerExpandTransitionMetrics metrics =
          PlayerExpandTransitionMetrics.compute(
            progress: progress,
            miniPlayerHeight: miniPlayerHeight,
            interactiveDrag: interactiveDrag,
            collapseBiased: collapseBiasedAt(progress),
            interactiveCollapseAnchor: interactiveCollapseAnchor,
          );
      if (hasChromeVisibilityGap(metrics)) {
        gaps.add(progress);
      }
    }
    return gaps;
  }

  /// Progress must only decrease when applying downward drag deltas.
  static bool isMonotonicDecreasing(List<double> timeline) {
    for (int i = 1; i < timeline.length; i++) {
      if (timeline[i] > timeline[i - 1] + 0.0001) {
        return false;
      }
    }
    return true;
  }
}

/// One detected discontinuity in transition metrics during a drag timeline.
class MetricJump {
  const MetricJump({
    required this.progress,
    required this.metric,
    required this.delta,
    required this.before,
    required this.after,
  });

  final double progress;
  final String metric;
  final double delta;
  final double before;
  final double after;

  @override
  String toString() =>
      'MetricJump($metric @ progress=${progress.toStringAsFixed(3)} '
      'Δ=${delta.toStringAsFixed(3)} $before→$after)';
}
