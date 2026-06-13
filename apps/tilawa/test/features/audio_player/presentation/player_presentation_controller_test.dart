import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_phase.dart';
import 'package:tilawa/core/navigation/quran_player_navigation.dart';
import 'package:tilawa/features/audio_player/presentation/player_shell_overlay_host.dart';
import 'package:tilawa/shared/widgets/quran_player_transition_test_utils.dart';

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

    test(
      'expand reconciles stale routeOpen after route leaves stack',
      () async {
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
      },
    );

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

    test('shell overlay mid progress is not collapse biased while idle', () {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.syncShellOverlayProgress(
        progress: 0.733,
        status: AnimationStatus.forward,
        isCollapsing: false,
        isUserDragging: false,
      );
      expect(controller.snapshot()['collapseBiased'], isFalse);
      controller.debugReset();
    });

    test('shell overlay drag at zero progress keeps isDragging', () {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.syncShellOverlayProgress(
        progress: 0,
        status: AnimationStatus.forward,
        isCollapsing: false,
        isUserDragging: true,
      );
      expect(controller.isDragging, isTrue);
      controller.debugReset();
    });

    test('expand uses shell overlay when host is bound', () async {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);

      final Future<void> expandFuture = controller.expand();
      await Future<void>.delayed(Duration.zero);
      expect(navigation.pushCount, 0);
      expect(shell.expandCount, 1);
      expect(controller.phase, PlayerPresentationPhase.expanding);

      controller.syncShellOverlayProgress(
        progress: 1,
        status: AnimationStatus.completed,
        isCollapsing: false,
        isUserDragging: false,
      );
      expect(controller.phase, PlayerPresentationPhase.expanded);
      shell.completeExpand();
      await expandFuture;

      controller.collapse();
      expect(shell.collapseCount, 1);
      expect(navigation.popCount, 0);
      expect(controller.phase, PlayerPresentationPhase.collapsing);

      controller.syncShellOverlayProgress(
        progress: 0,
        status: AnimationStatus.dismissed,
        isCollapsing: true,
        isUserDragging: false,
      );
      shell.completeCollapse();
      expect(controller.phase, PlayerPresentationPhase.mini);
      expect(controller.snapshot()['collapseBiased'], isFalse);
    });

    test(
      'audit: onRouteOpened collapses shell when overlay was expanded',
      () {
        final _FakeShellHost shell = _FakeShellHost();
        controller.bindShellOverlay(shell);
        controller.syncShellOverlayProgress(
          progress: 1,
          status: AnimationStatus.completed,
          isCollapsing: false,
          isUserDragging: false,
        );
        expect(controller.phase, PlayerPresentationPhase.expanded);

        controller.onRouteOpened();

        expect(shell.collapseCount, 1);
        expect(controller.routeOpen, isTrue);
        expect(controller.transitionProgress, closeTo(0, 0.001));
      },
    );

    test(
      'audit: syncShellOverlayProgress is ignored while route is open',
      () {
        final _FakeShellHost shell = _FakeShellHost();
        controller.bindShellOverlay(shell);

        controller.onRouteOpened();
        controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
        controller.onRouteAnimationTick(1, AnimationStatus.completed);
        expect(controller.routeOpen, isTrue);
        expect(controller.transitionProgress, closeTo(1, 0.001));

        controller.syncShellOverlayProgress(
          progress: 0.4,
          status: AnimationStatus.forward,
          isCollapsing: false,
          isUserDragging: true,
        );

        expect(controller.transitionProgress, closeTo(1, 0.001));
        expect(controller.isDragging, isFalse);
        expect(controller.phase, PlayerPresentationPhase.expanded);
      },
    );

    test('ignores spurious completed@1.0 before forward animation', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      expect(controller.transitionProgress, closeTo(0, 0.001));
      expect(controller.phase, isNot(PlayerPresentationPhase.expanded));
    });

    test(
      'spurious spike helper matches controller ignore semantics',
      () {
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
      },
    );

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

    test('bindShellOverlay attaches host and allows shell expand', () async {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      expect(controller.hasShellOverlayHost, isTrue);
      unawaited(controller.expand());
      await Future<void>.delayed(Duration.zero);
      expect(shell.expandCount, 1);
      shell.completeExpand();
    });

    test('unbindShellOverlay clears host and resets presentation', () {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.syncShellOverlayProgress(
        progress: 0.8,
        status: AnimationStatus.forward,
        isCollapsing: false,
        isUserDragging: false,
      );
      controller.unbindShellOverlay(shell);
      expect(controller.hasShellOverlayHost, isFalse);
      expect(controller.phase, PlayerPresentationPhase.mini);
    });

    test('unbindShellOverlay ignores non-matching host', () {
      final _FakeShellHost shell = _FakeShellHost();
      final _FakeShellHost other = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.unbindShellOverlay(other);
      expect(controller.hasShellOverlayHost, isTrue);
    });

    test('shell getters report overlay and expanded state', () {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.syncShellOverlayProgress(
        progress: 1,
        status: AnimationStatus.completed,
        isCollapsing: false,
        isUserDragging: false,
      );
      expect(controller.isExpandedSettled, isTrue);
      expect(controller.overlayChromeActive, isTrue);
      expect(controller.transitionOwner, 'shellExpanded');
      expect(controller.renderTree, 'shellExpanded');
      expect(controller.isMiniSettled, isFalse);
    });

    test('visualProgress is zero only in settled mini phase', () {
      expect(controller.visualProgress, 0);
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.4, AnimationStatus.forward);
      expect(controller.visualProgress, closeTo(0.4, 0.001));
    });

    test('route transitionOwner and renderTree during expand', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.6, AnimationStatus.forward);
      expect(controller.transitionOwner, 'route');
      expect(controller.renderTree, 'routeTransition');
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      expect(controller.transitionOwner, 'routeSettled');
      expect(controller.renderTree, 'routeExpanded');
    });

    test('collapseBiasedForMetrics after shell reverse animation', () {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.syncShellOverlayProgress(
        progress: 0.5,
        status: AnimationStatus.reverse,
        isCollapsing: true,
        isUserDragging: false,
      );
      expect(controller.collapseBiasedForMetrics, isTrue);
    });

    test('shell collapse is no-op when already mini', () {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.collapse();
      expect(shell.collapseCount, 0);
    });

    test('expand short-circuits when route already on stack', () async {
      navigation.expandedOnStack = true;
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      await controller.expand();
      expect(navigation.pushCount, 0);
      expect(controller.routeOpen, isTrue);
      expect(controller.phase, PlayerPresentationPhase.expanded);
    });

    test('expand closes route when push completes at zero progress', () async {
      navigation.completePushImmediately = true;
      await controller.expand();
      expect(controller.phase, PlayerPresentationPhase.mini);
      expect(controller.routeOpen, isFalse);
    });

    test('onRouteClosed is idempotent when already mini', () {
      controller.onRouteClosed();
      expect(controller.phase, PlayerPresentationPhase.mini);
      controller.onRouteClosed();
      expect(controller.phase, PlayerPresentationPhase.mini);
    });

    test('onRouteClosed via public API resets route state', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.onRouteClosed();
      expect(controller.routeOpen, isFalse);
      expect(controller.transitionProgress, 0);
    });

    test('shouldRestoreExpandedRoute when route lost mid-expand', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.6, AnimationStatus.forward);
      navigation.expandedOnStack = false;
      expect(controller.shouldRestoreExpandedRoute, isTrue);
    });

    test('hero expanded drag end collapses on downward fling', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.onHeroExpandedDragStart();
      controller.onHeroExpandedDragUpdate(120);
      controller.onHeroExpandedDragEnd(
        primaryVelocity: 800,
        progressThreshold: 0.45,
        velocityThreshold: 500,
      );
      expect(controller.phase, PlayerPresentationPhase.collapsing);
      expect(navigation.popCount, 1);
    });

    test('hero expanded drag end stays expanded on upward fling', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.onHeroExpandedDragStart();
      controller.onHeroExpandedDragEnd(
        primaryVelocity: -900,
        progressThreshold: 0.45,
        velocityThreshold: 500,
      );
      expect(controller.phase, PlayerPresentationPhase.expanded);
      expect(navigation.popCount, 0);
    });

    test('metricsForFooter uses route handoff when route open', () {
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.5, AnimationStatus.forward);
      final metrics = controller.metricsForFooter(miniPlayerHeight: 96);
      expect(metrics.showExpandedSheet, isTrue);
    });

    test('bind and unbind system back and dismiss handles', () {
      var backCalls = 0;
      var dismissCalls = 0;
      void back() => backCalls++;
      void dismiss() => dismissCalls++;

      controller.bindSystemBack(handle: back);
      controller.bindDismissPlayer(handle: dismiss);
      controller.setInterceptsAllowed(false);
      controller.setInterceptsAllowed(true);
      controller.dismissPlayer();
      expect(dismissCalls, 1);

      controller.unbindSystemBack(handle: dismiss);
      expect(backCalls, 0);
      controller.unbindSystemBack(handle: back);
      controller.unbindDismissPlayer(handle: dismiss);
      controller.dismissPlayer();
      expect(dismissCalls, 1);
    });

    test('syncShellOverlayProgress sets collapsing phase on reverse', () {
      final _FakeShellHost shell = _FakeShellHost();
      controller.bindShellOverlay(shell);
      controller.syncShellOverlayProgress(
        progress: 0.4,
        status: AnimationStatus.reverse,
        isCollapsing: true,
        isUserDragging: false,
      );
      expect(controller.phase, PlayerPresentationPhase.collapsing);
    });

    test('notifies listeners after route animation tick', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.onRouteOpened();
      controller.onRouteAnimationTick(0.2, AnimationStatus.forward);
      controller.notifyListeners();
      expect(notifications, greaterThan(0));
    });
  });
}

final class _FakeShellHost implements PlayerShellOverlayHost {
  int expandCount = 0;
  int collapseCount = 0;
  Completer<void>? _expandCompleter;
  Completer<void>? _collapseCompleter;

  @override
  Future<void> expand() async {
    expandCount++;
    _expandCompleter = Completer<void>();
    return _expandCompleter!.future;
  }

  void completeExpand() {
    _expandCompleter?.complete();
    _expandCompleter = null;
  }

  @override
  Future<void> collapse() async {
    collapseCount++;
    _collapseCompleter = Completer<void>();
    return _collapseCompleter!.future;
  }

  void completeCollapse() {
    _collapseCompleter?.complete();
    _collapseCompleter = null;
  }
}

final class _FakeNavigation implements QuranPlayerNavigation {
  int pushCount = 0;
  int popCount = 0;
  bool expandedOnStack = false;
  bool completePushImmediately = false;
  Completer<void>? _pushCompleter;

  @override
  bool get isExpandedRouteOnStack => expandedOnStack;

  @override
  Future<void> pushExpanded() async {
    pushCount++;
    expandedOnStack = true;
    if (completePushImmediately) {
      expandedOnStack = false;
      return;
    }
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
