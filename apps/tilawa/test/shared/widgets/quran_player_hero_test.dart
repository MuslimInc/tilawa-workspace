import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';
import 'package:tilawa/shared/widgets/quran_player_hero.dart';
import 'package:tilawa/shared/widgets/quran_player_hero_expansion.dart';

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

  group('QuranPlayerHeroExpansionSnapshot', () {
    test('visual progress follows route animation in hero mode', () {
      const QuranPlayerHeroExpansionSnapshot snap =
          QuranPlayerHeroExpansionSnapshot(
        routeOpen: true,
        routeProgress: 0.35,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesHeroExpansion: true,
      );

      expect(snap.visualProgress, 0.35);
      expect(snap.transitionOwner, 'heroRoute');
      expect(snap.renderTree, 'heroTransition');
    });

    test('footer mini metrics fade as route progresses', () {
      const QuranPlayerHeroExpansionSnapshot mid =
          QuranPlayerHeroExpansionSnapshot(
        routeOpen: true,
        routeProgress: 0.25,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesHeroExpansion: true,
      );
      final PlayerExpandTransitionMetrics metrics = mid.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
      );

      expect(metrics.miniOpacity, greaterThan(0));
      expect(metrics.miniOpacity, lessThan(1));
      expect(metrics.showExpandedSheet, isTrue);
    });

    test('settled expanded hides footer mini chrome', () {
      const QuranPlayerHeroExpansionSnapshot settled =
          QuranPlayerHeroExpansionSnapshot(
        routeOpen: true,
        routeProgress: 1,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesHeroExpansion: true,
      );
      final PlayerExpandTransitionMetrics metrics = settled.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
      );

      expect(metrics.miniOpacity, 0);
      expect(metrics.showMiniPlayer, isFalse);
      expect(settled.transitionOwner, 'heroRouteSettled');
    });

    test('hero handoff keeps mini visible longer during expand', () {
      const QuranPlayerHeroExpansionSnapshot mid =
          QuranPlayerHeroExpansionSnapshot(
        routeOpen: true,
        routeProgress: 0.45,
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesHeroExpansion: true,
      );
      final PlayerExpandTransitionMetrics defaultMetrics = mid.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
      );
      final PlayerExpandTransitionMetrics heroMetrics = mid.metrics(
        miniPlayerHeight: 96,
        collapseBiased: false,
        heroHandoff: true,
      );

      expect(heroMetrics.miniOpacity, greaterThan(defaultMetrics.miniOpacity));
    });
  });

  group('isSpuriousHeroRouteProgressSpike', () {
    test('ignores completed@1.0 before forward is seen', () {
      expect(
        isSpuriousHeroRouteProgressSpike(
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
        isSpuriousHeroRouteProgressSpike(
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

  group('QuranPlayerHeroRouteProgress', () {
    test('tick notifies listeners and updates snapshot', () {
      final QuranPlayerHeroRouteProgress progress =
          QuranPlayerHeroRouteProgress();
      addTearDown(progress.dispose);

      var notifications = 0;
      progress.addListener(() => notifications++);

      progress.beginRoute();
      expect(progress.routeOpen, isTrue);
      expect(progress.value, 0);

      progress.tick(0.4);
      expect(progress.value, 0.4);
      expect(notifications, greaterThan(0));

      final QuranPlayerHeroExpansionSnapshot snap = progress.snapshot(
        controllerProgress: 0,
        isCollapsing: false,
        isDragging: false,
        usesHeroExpansion: true,
      );
      expect(snap.visualProgress, 0.4);

      progress.endRoute();
      expect(progress.routeOpen, isFalse);
      expect(progress.value, 0);
    });
  });
}
