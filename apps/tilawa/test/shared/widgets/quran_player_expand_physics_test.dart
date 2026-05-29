import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

void main() {
  group('QuranPlayerExpandPhysics.applyDragDelta', () {
    test('dragging down reduces progress proportionally', () {
      const double travel = 800;
      final double next = QuranPlayerExpandPhysics.applyDragDelta(
        current: 1,
        dragPixels: 400,
        travelPixels: travel,
      );
      expect(next, closeTo(0.5, 0.001));
    });

    test('rubber-bands past collapsed without exceeding extent', () {
      final double next = QuranPlayerExpandPhysics.applyDragDelta(
        current: 0,
        dragPixels: 400,
        travelPixels: 800,
        rubberBandExtent: 0.08,
      );
      expect(next, inInclusiveRange(-0.08, 0));
    });
  });

  group('QuranPlayerExpandPhysics.resolveSnap', () {
    test('strong upward fling expands regardless of position', () {
      final PlayerExpandSnapTarget target =
          QuranPlayerExpandPhysics.resolveSnap(
        progress: 0.1,
        primaryVelocity: -600,
        progressThreshold: 0.45,
        velocityThreshold: 500,
      );
      expect(target, PlayerExpandSnapTarget.expand);
    });

    test('strong downward fling collapses', () {
      final PlayerExpandSnapTarget target =
          QuranPlayerExpandPhysics.resolveSnap(
        progress: 0.9,
        primaryVelocity: 400,
        progressThreshold: 0.45,
        velocityThreshold: 500,
      );
      expect(target, PlayerExpandSnapTarget.collapse);
    });

    test('mid drag snaps by progress threshold', () {
      expect(
        QuranPlayerExpandPhysics.resolveSnap(
          progress: 0.5,
          primaryVelocity: 0,
          progressThreshold: 0.45,
          velocityThreshold: 500,
        ),
        PlayerExpandSnapTarget.expand,
      );

      expect(
        QuranPlayerExpandPhysics.resolveSnap(
          progress: 0.4,
          primaryVelocity: 0,
          progressThreshold: 0.45,
          velocityThreshold: 500,
        ),
        PlayerExpandSnapTarget.collapse,
      );
    });

    test('downward net drag collapses even above progress threshold', () {
      final PlayerExpandSnapTarget target =
          QuranPlayerExpandPhysics.resolveSnap(
        progress: 0.846,
        primaryVelocity: 0,
        progressThreshold: 0.45,
        velocityThreshold: 500,
        netDragDy: 120,
      );
      expect(target, PlayerExpandSnapTarget.collapse);
    });
  });

  group('PlayerExpandTransitionMetrics', () {
    test('mini and expanded overlap mid-transition (no white gap)', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.20,
        miniPlayerHeight: 72,
      );
      expect(
        mid.miniOpacity + mid.expandedOpacity,
        greaterThan(0.15),
      );
      expect(mid.showMiniPlayer || mid.showExpandedSheet, isTrue);
    });

    test('queue chrome appears only near fully expanded', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.5,
        miniPlayerHeight: 72,
      );
      expect(mid.queueChromeT, 0);

      final PlayerExpandTransitionMetrics full =
          PlayerExpandTransitionMetrics.compute(
        progress: 1,
        miniPlayerHeight: 72,
      );
      expect(full.queueChromeT, closeTo(1, 0.01));
    });

    test('collapsed shows mini hides expanded', () {
      final PlayerExpandTransitionMetrics collapsed =
          PlayerExpandTransitionMetrics.compute(
        progress: 0,
        miniPlayerHeight: 72,
      );
      expect(collapsed.showMiniPlayer, isTrue);
      expect(collapsed.showExpandedSheet, isFalse);
    });

    test('sheet presentation fades during expand crossfade band', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.20,
        miniPlayerHeight: 72,
      );
      expect(
        mid.sheetPresentationOpacity,
        lessThan(mid.expandedOpacity),
      );
      expect(mid.sheetPresentationOpacity, lessThan(0.35));
    });

    test('collapse start keeps sheet visible at progress 1', () {
      final PlayerExpandTransitionMetrics start =
          PlayerExpandTransitionMetrics.compute(
        progress: 1,
        miniPlayerHeight: 72,
        collapseBiased: true,
      );
      expect(start.sheetPresentationOpacity, closeTo(1, 0.01));
      expect(start.showExpandedSheet, isTrue);
    });

    test('collapse route dims sheet with progress', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.30,
        miniPlayerHeight: 72,
        collapseBiased: true,
      );
      expect(mid.sheetPresentationOpacity, lessThan(0.25));
      expect(mid.handoffT, greaterThan(0.2));
      expect(mid.showMorphLayer, isTrue);
    });

    test('hero collapse keeps footer mini in handoff longer', () {
      final PlayerExpandTransitionMetrics withoutHero =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.35,
        miniPlayerHeight: 72,
        collapseBiased: true,
        heroHandoff: false,
      );
      final PlayerExpandTransitionMetrics withHero =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.35,
        miniPlayerHeight: 72,
        collapseBiased: true,
        heroHandoff: true,
      );
      expect(withHero.miniOpacity, greaterThan(withoutHero.miniOpacity));
      expect(withHero.showMiniPlayer, isTrue);
    });

    test('settled expanded keeps full sheet opacity', () {
      final PlayerExpandTransitionMetrics settled =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.99,
        miniPlayerHeight: 72,
      );
      expect(settled.sheetPresentationOpacity, closeTo(1, 0.01));
      expect(settled.backdropOpacity, closeTo(0.92, 0.01));
    });

    test('late collapse drag clears scrim and backdrop', () {
      final PlayerExpandTransitionMetrics dragging =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.08,
        miniPlayerHeight: 72,
        collapseBiased: true,
      );
      expect(dragging.sheetPresentationOpacity, lessThan(0.08));
      expect(dragging.scrimOpacity, lessThan(0.05));
      expect(dragging.backdropOpacity, lessThan(0.08));
      expect(dragging.handoffT, greaterThan(0.05));
    });

    test('handoff peaks mid-transition and hides at endpoints', () {
      expect(
        PlayerExpandTransitionMetrics.compute(
          progress: 0,
          miniPlayerHeight: 72,
        ).handoffT,
        0,
      );
      expect(
        PlayerExpandTransitionMetrics.compute(
          progress: 1,
          miniPlayerHeight: 72,
        ).handoffT,
        0,
      );
      final double peak = PlayerExpandTransitionMetrics.compute(
        progress: 0.5,
        miniPlayerHeight: 72,
      ).handoffT;
      expect(peak, greaterThan(0.85));
    });

    test('stage and mini identity fade during handoff', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.35,
        miniPlayerHeight: 72,
      );
      expect(mid.showMorphLayer, isTrue);
      expect(mid.stageChromeOpacity, lessThan(0.4));
      expect(mid.miniIdentityOpacity, lessThan(0.4));
    });
  });
}
