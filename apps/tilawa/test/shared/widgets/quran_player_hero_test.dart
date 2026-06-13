import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';
import 'package:tilawa/shared/widgets/quran_player_hero_tags.dart';
import 'package:tilawa/shared/widgets/quran_player_transition_test_utils.dart';

void main() {
  group('QuranPlayerHeroTags', () {
    test('artwork tag is stable per audio id', () {
      expect(
        QuranPlayerHeroTags.artwork('42'),
        'quran_player_artwork_42',
      );
    });

    test('metadata tag is stable per audio id', () {
      expect(
        QuranPlayerHeroTags.metadata('42'),
        'quran_player_metadata_42',
      );
    });
  });

  group('QuranPlayerExpansionSnapshot', () {
    test('visual progress follows route animation in route mode', () {
      const QuranPlayerExpansionSnapshot snap = QuranPlayerExpansionSnapshot(
        routeOpen: true,
        routeProgress: 0.35,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesRouteExpansion: true,
      );

      expect(snap.visualProgress, 0.35);
      expect(snap.transitionOwner, 'route');
      expect(snap.renderTree, 'routeTransition');
    });

    test('footer mini metrics fade as route progresses', () {
      const QuranPlayerExpansionSnapshot mid = QuranPlayerExpansionSnapshot(
        routeOpen: true,
        routeProgress: 0.45,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesRouteExpansion: true,
      );
      final PlayerExpandTransitionMetrics metrics = mid.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
        heroHandoff: true,
      );

      expect(metrics.miniOpacity, greaterThan(0));
      expect(metrics.miniOpacity, lessThan(1));
      expect(metrics.showExpandedSheet, isTrue);
    });

    test('settled expanded hides footer mini chrome', () {
      const QuranPlayerExpansionSnapshot settled = QuranPlayerExpansionSnapshot(
        routeOpen: true,
        routeProgress: 1,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesRouteExpansion: true,
      );
      final PlayerExpandTransitionMetrics metrics = settled.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
      );

      expect(metrics.miniOpacity, 0);
      expect(metrics.showMiniPlayer, isFalse);
      expect(settled.transitionOwner, 'routeSettled');
    });

    test('route handoff keeps mini visible longer during expand', () {
      const QuranPlayerExpansionSnapshot mid = QuranPlayerExpansionSnapshot(
        routeOpen: true,
        routeProgress: 0.45,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesRouteExpansion: true,
      );
      final PlayerExpandTransitionMetrics defaultMetrics = mid.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
      );
      final PlayerExpandTransitionMetrics handoffMetrics = mid.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
        heroHandoff: true,
      );

      expect(
        handoffMetrics.miniOpacity,
        greaterThan(defaultMetrics.miniOpacity),
      );
    });

    test('isTransitioning is true only during open mid-progress route', () {
      const QuranPlayerExpansionSnapshot mid = QuranPlayerExpansionSnapshot(
        routeOpen: true,
        routeProgress: 0.5,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesRouteExpansion: true,
      );
      expect(mid.isTransitioning, isTrue);
      expect(mid.isExpandedSettled, isFalse);
      expect(mid.isMiniSettled, isFalse);
    });

    test('routeClosing transitionOwner when route animates out', () {
      const QuranPlayerExpansionSnapshot closing = QuranPlayerExpansionSnapshot(
        routeOpen: false,
        routeProgress: 0.2,
        controllerProgress: 0,
        isCollapsing: true,
        isDragging: false,
        usesRouteExpansion: true,
      );
      expect(closing.transitionOwner, 'routeClosing');
      expect(closing.renderTree, 'footerMini');
      expect(closing.isTransitioning, isFalse);
    });

    test('shell overlay uses controller progress when route is closed', () {
      const QuranPlayerExpansionSnapshot snap = QuranPlayerExpansionSnapshot(
        routeOpen: false,
        routeProgress: 0,
        controllerProgress: 0.6,
        isCollapsing: false,
        isDragging: true,
        usesRouteExpansion: false,
      );

      expect(snap.visualProgress, 0.6);
      expect(snap.transitionOwner, 'expandController');
    });
  });

  group('isSpuriousRouteProgressSpike', () {
    test('ignores completed@1.0 before forward is seen', () {
      expect(
        isSpuriousRouteProgressSpike(
          seenForward: false,
          seenReverse: false,
          status: AnimationStatus.completed,
          value: 1,
          currentProgress: 0,
        ),
        isTrue,
      );
    });

    test('accepts forward progress after animation starts', () {
      expect(
        isSpuriousRouteProgressSpike(
          seenForward: true,
          seenReverse: false,
          status: AnimationStatus.forward,
          value: 0.35,
          currentProgress: 0.1,
        ),
        isFalse,
      );
    });
  });
}
