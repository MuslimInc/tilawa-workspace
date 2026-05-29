import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_phase.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerPresentationController', () {
    late _FakeNavigation navigation;
    late PlayerPresentationController controller;

    setUp(() {
      navigation = _FakeNavigation();
      controller = PlayerPresentationController(navigation);
    });

    tearDown(() {
      controller.debugReset();
    });

    test('expand pushes route and settles to mini after pop', () async {
      final Future<void> pushFuture = controller.expand();
      await Future<void>.delayed(Duration.zero);
      expect(navigation.pushCount, 1);
      expect(controller.phase, PlayerPresentationPhase.expanding);

      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
      controller.onRouteAnimationTick(1, AnimationStatus.completed);

      expect(controller.phase, PlayerPresentationPhase.expanded);

      controller.collapse();
      controller.onRouteAnimationTick(0, AnimationStatus.dismissed);
      navigation.completePush();
      await pushFuture;

      expect(controller.phase, PlayerPresentationPhase.mini);
      expect(controller.routeOpen, isFalse);
      expect(controller.snapshot()['collapseBiased'], isFalse);
    });

    test('collapse pops navigation', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.collapse();
      expect(navigation.popCount, 1);
      expect(controller.phase, PlayerPresentationPhase.collapsing);
    });

    test('expand reconciles stale routeOpen after route leaves stack', () async {
      unawaited(controller.expand());
      await Future<void>.delayed(Duration.zero);
      controller.onRouteOpened();
      controller.collapse();
      navigation.completePush();
      await Future<void>.delayed(Duration.zero);
      expect(controller.phase, PlayerPresentationPhase.mini);

      final Future<void> secondExpand = controller.expand();
      await Future<void>.delayed(Duration.zero);
      expect(navigation.pushCount, 2);
      expect(controller.phase, PlayerPresentationPhase.expanding);
      expect(controller.snapshot()['collapseBiased'], isFalse);
      navigation.completePush();
      await secondExpand;
    });

    test('re-expand after collapse pushes /player again', () async {
      unawaited(controller.expand());
      await Future<void>.delayed(Duration.zero);
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.collapse();
      controller.onRouteAnimationTick(0, AnimationStatus.dismissed);
      navigation.completePush();
      await Future<void>.delayed(Duration.zero);
      expect(controller.phase, PlayerPresentationPhase.mini);

      unawaited(controller.expand());
      await Future<void>.delayed(Duration.zero);
      expect(navigation.pushCount, 2);
      expect(controller.phase, PlayerPresentationPhase.expanding);
      expect(controller.snapshot()['collapseBiased'], isFalse);
      navigation.completePush();
    });

    test('expand collapse expand cycle', () async {
      unawaited(controller.expand());
      await Future<void>.delayed(Duration.zero);
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      expect(controller.phase, PlayerPresentationPhase.expanded);

      controller.collapse();
      controller.onRouteAnimationTick(0, AnimationStatus.dismissed);
      navigation.completePush();
      await Future<void>.delayed(Duration.zero);
      expect(controller.phase, PlayerPresentationPhase.mini);

      unawaited(controller.expand());
      await Future<void>.delayed(Duration.zero);
      expect(navigation.pushCount, 2);
      expect(controller.phase, PlayerPresentationPhase.expanding);
      navigation.completePush();
    });

    test('reverse animation to zero closes presentation', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.forward);
      controller.onRouteAnimationTick(0, AnimationStatus.dismissed);
      expect(controller.phase, PlayerPresentationPhase.mini);
      expect(controller.routeOpen, isFalse);
    });

    test('shouldRestoreExpandedRoute is false during user collapse', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.collapse();
      expect(controller.shouldRestoreExpandedRoute, isFalse);
    });

    test('reconcileWithNavigationStack clears stale routeOpen', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      expect(controller.routeOpen, isTrue);
      navigation.completePush();
      controller.reconcileWithNavigationStack();
      expect(controller.routeOpen, isFalse);
      expect(controller.phase, PlayerPresentationPhase.mini);
    });

    test('coalesced expand waiters do not re-push after collapse', () async {
      final Future<void> first = controller.expand();
      final Future<void> second = controller.expand();
      await Future<void>.delayed(Duration.zero);
      expect(navigation.pushCount, 1);

      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.collapse();
      controller.onRouteAnimationTick(0, AnimationStatus.dismissed);
      navigation.completePush();
      await first;
      await second;

      expect(navigation.pushCount, 1);
      expect(controller.phase, PlayerPresentationPhase.mini);
      expect(controller.routeOpen, isFalse);
    });

    test('reconcileWithNavigationStack ignores user collapse', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.collapse();
      navigation.expandedOnStack = false;
      controller.reconcileWithNavigationStack();
      expect(controller.routeOpen, isTrue);
      expect(controller.phase, PlayerPresentationPhase.collapsing);
    });

    test('collapse keeps collapseBiased until reverse animation ends', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.collapse();
      expect(controller.snapshot()['collapseBiased'], isTrue);

      controller.onRouteAnimationTick(0.5, AnimationStatus.reverse);
      expect(controller.snapshot()['collapseBiased'], isTrue);
      expect(controller.visualProgress, closeTo(0.5, 0.001));

      navigation.completePush();
      expect(controller.snapshot()['collapseBiased'], isTrue);

      controller.onRouteAnimationTick(0, AnimationStatus.dismissed);
      expect(controller.phase, PlayerPresentationPhase.mini);
      expect(controller.snapshot()['collapseBiased'], isFalse);
    });
  });
}

final class _FakeNavigation implements QuranPlayerNavigation {
  int pushCount = 0;
  int popCount = 0;
  bool expandedOnStack = false;
  Completer<void>? _pushCompleter;

  @override
  bool get isExpandedRouteOnStack => expandedOnStack;

  @override
  Future<void> pushExpanded() async {
    pushCount++;
    expandedOnStack = true;
    _pushCompleter = Completer<void>();
    return _pushCompleter!.future;
  }

  void completePush() {
    expandedOnStack = false;
    _pushCompleter?.complete();
    _pushCompleter = null;
  }

  @override
  void popExpanded() {
    popCount++;
    completePush();
  }
}
