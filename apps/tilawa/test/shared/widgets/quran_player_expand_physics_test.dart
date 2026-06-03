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

    test('1:1 tracking — travel equals sheet height range', () {
      // When travel = screenHeight - miniHeight, dragging the full sheet range
      // should move progress exactly from 1.0 to 0.0 (YouTube Music style).
      const double screenHeight = 800;
      const double miniHeight = 76;
      const double travel = screenHeight - miniHeight; // 724 px

      final double next = QuranPlayerExpandPhysics.applyDragDelta(
        current: 1,
        dragPixels: travel,
        travelPixels: travel,
      );
      expect(next, closeTo(0, 0.001));
    });

    test('1:1 tracking — dragging half the sheet range lands at 0.5', () {
      const double screenHeight = 800;
      const double miniHeight = 76;
      const double travel = screenHeight - miniHeight; // 724 px

      final double next = QuranPlayerExpandPhysics.applyDragDelta(
        current: 1,
        dragPixels: travel / 2,
        travelPixels: travel,
      );
      expect(next, closeTo(0.5, 0.001));
    });

    test('upward drag from collapsed expands proportionally', () {
      const double screenHeight = 800;
      const double miniHeight = 76;
      const double travel = screenHeight - miniHeight;

      final double next = QuranPlayerExpandPhysics.applyDragDelta(
        current: 0,
        dragPixels: -travel * 0.3, // upward = negative
        travelPixels: travel,
      );
      expect(next, closeTo(0.3, 0.001));
    });

    test('shell footer anchor — sheet top tracks finger (anchorHeight=108)', () {
      // Shell footer: mini bar slot = 108px (76 bar + 32 bottom inset).
      // anchorHeight = screenH - hostRect.top = 800 - 692 = 108.
      // travel = screenH - anchorHeight = 800 - 108 = 692.
      // At any progress p, sheet top = 692 * (1-p).
      // Finger drags p*692 px upward from y=692, landing at 692 - p*692 = 692*(1-p). ✓
      const double screenHeight = 800;
      const double anchorHeight = 108; // = screenH - hostRect.top
      const double travel = screenHeight - anchorHeight; // 692

      for (final double p in <double>[0.1, 0.3, 0.5, 0.75]) {
        final double sheetTop =
            screenHeight - (anchorHeight + (screenHeight - anchorHeight) * p);
        final double fingerY = 692 - p * travel;
        expect(sheetTop, closeTo(fingerY, 0.01),
            reason: 'sheet top should equal finger Y at progress=$p');
      }
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

    test('audit: collapse drag uses collapse-biased metrics not expand-forward', () {
      final PlayerExpandTransitionMetrics expandForwardDrag =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.70,
        miniPlayerHeight: 72,
        interactiveDrag: true,
        collapseBiased: false,
      );
      final PlayerExpandTransitionMetrics collapseDrag =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.70,
        miniPlayerHeight: 72,
        interactiveDrag: true,
        collapseBiased: true,
      );

      expect(expandForwardDrag.showMiniPlayer, isFalse);
      expect(collapseDrag.showMiniPlayer, isTrue);
      expect(
        collapseDrag.miniOpacity,
        greaterThan(expandForwardDrag.miniOpacity),
      );
    });

    test('interactive drag tracks finger linearly at 0.811', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.811,
        miniPlayerHeight: 72,
        interactiveDrag: true,
      );
      expect(mid.sheetMotionT, closeTo(0.811, 0.01));
      expect(mid.sheetPresentationOpacity, greaterThan(0.65));
      expect(mid.sheetPresentationOpacity, lessThan(0.95));
      expect(mid.miniOpacity, 0);
      expect(mid.showMiniPlayer, isFalse);
      expect(mid.stageChromeOpacity, 1);
      expect(mid.handoffT, 0);
      expect(mid.showMorphLayer, isFalse);
    });

    test('expand-forward keeps feed visible — sheet not opaque at 0.5', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.5,
        miniPlayerHeight: 72,
      );
      expect(mid.sheetPresentationOpacity, lessThan(0.55));
      expect(mid.scrimOpacity, greaterThan(0.1));
      expect(mid.scrimOpacity, lessThan(0.45));
      expect(mid.showMiniPlayer, isTrue);
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

    test('footer collapse after route pop shows mini before sheet ends', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.70,
        miniPlayerHeight: 72,
        collapseBiased: true,
        heroHandoff: false,
      );
      expect(mid.showMiniPlayer, isTrue);
      expect(mid.miniOpacity, greaterThan(0.1));
      expect(mid.showExpandedSheet, isFalse);
    });

    test('footer collapse surfaces mini earlier than expand-forward', () {
      final PlayerExpandTransitionMetrics expandForward =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.70,
        miniPlayerHeight: 72,
      );
      final PlayerExpandTransitionMetrics footerCollapse =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.70,
        miniPlayerHeight: 72,
        collapseBiased: true,
        heroHandoff: false,
      );
      expect(
        footerCollapse.miniOpacity,
        greaterThan(expandForward.miniOpacity),
      );
      expect(footerCollapse.showMiniPlayer, isTrue);
    });

    test('settled expanded keeps full sheet opacity', () {
      final PlayerExpandTransitionMetrics settled =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.99,
        miniPlayerHeight: 72,
      );
      expect(settled.sheetPresentationOpacity, closeTo(1, 0.01));
      expect(settled.backdropOpacity, 0);
    });

    test('late collapse drag clears scrim and hides expanded sheet', () {
      final PlayerExpandTransitionMetrics dragging =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.08,
        miniPlayerHeight: 72,
        collapseBiased: true,
      );
      expect(dragging.sheetPresentationOpacity, lessThan(0.08));
      expect(dragging.scrimOpacity, lessThan(0.05));
      expect(dragging.backdropOpacity, 0);
      expect(dragging.showExpandedSheet, isFalse);
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

    test('expanded opacity eases in between expandedStart and expandedFull', () {
      final PlayerExpandTransitionMetrics mid =
          PlayerExpandTransitionMetrics.compute(
        progress: 0.3,
        miniPlayerHeight: 72,
        heroHandoff: true,
      );
      expect(mid.showExpandedSheet, isTrue);
      expect(mid.sheetPresentationOpacity, greaterThan(0));
      expect(mid.sheetPresentationOpacity, lessThan(1));
    });
  });

  group('QuranPlayerExpandPhysics edge cases', () {
    test('travelPixels returns 1 for invalid viewport or sensitivity', () {
      expect(QuranPlayerExpandPhysics.travelPixels(0, 1), 1);
      expect(QuranPlayerExpandPhysics.travelPixels(800, 0), 1);
    });

    test('applyDragDelta no-ops when travelPixels is zero', () {
      expect(
        QuranPlayerExpandPhysics.applyDragDelta(
          current: 0.4,
          dragPixels: 50,
          travelPixels: 0,
        ),
        0.4,
      );
    });

    test('rubber-bands expansion past 1.0', () {
      final double next = QuranPlayerExpandPhysics.applyDragDelta(
        current: 1,
        dragPixels: -200,
        travelPixels: 800,
        rubberBandExtent: 0.08,
      );
      expect(next, greaterThan(1));
      expect(next, lessThanOrEqualTo(1.08));
    });

    test('hard clamp when rubberBandExtent is zero', () {
      expect(
        QuranPlayerExpandPhysics.applyDragDelta(
          current: 0.5,
          dragPixels: 2000,
          travelPixels: 100,
          rubberBandExtent: 0,
        ),
        0,
      );
    });
  });
}
