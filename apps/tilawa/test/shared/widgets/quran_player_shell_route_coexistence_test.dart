import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/navigation/quran_player_navigation.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_phase.dart';
import 'package:tilawa/features/audio_player/presentation/player_shell_overlay_host.dart';

/// Mirrors [QuranPlayerWidget._shellOverlayPortalActive] and portal show logic.
bool shellOverlayPortalWantsShow({
  required double expandProgress,
  required bool isAnimating,
  required bool isUserDragging,
}) {
  return expandProgress > 0.01 || isAnimating || isUserDragging;
}

/// Reconciles footer [AnimationController] when presentation reports route closed.
///
/// Mirrors post-route-close handling in [QuranPlayerWidget].
void reconcileExpandAfterRouteClosed({
  required double expandProgress,
  required bool routeOpen,
  required PlayerPresentationPhase phase,
  required void Function(double nextProgress) setExpandProgress,
}) {
  if (!routeOpen &&
      phase == PlayerPresentationPhase.mini &&
      expandProgress > 0.01) {
    setExpandProgress(0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('audit: shell overlay portal vs /player route (review #1)', () {
    test(
      'portal stays visible when expand progress stuck at 1 after route pop',
      () {
        const double expandAfterRoutePop = 1.0;

        expect(
          shellOverlayPortalWantsShow(
            expandProgress: expandAfterRoutePop,
            isAnimating: false,
            isUserDragging: false,
          ),
          isTrue,
          reason:
              'documents desync: presentation mini but footer controller still '
              'expanded',
        );
      },
    );

    test('reconcileExpandAfterRouteClosed hides portal', () {
      var progress = 1.0;
      reconcileExpandAfterRouteClosed(
        expandProgress: progress,
        routeOpen: false,
        phase: PlayerPresentationPhase.mini,
        setExpandProgress: (double next) => progress = next,
      );

      expect(progress, 0);
      expect(
        shellOverlayPortalWantsShow(
          expandProgress: progress,
          isAnimating: false,
          isUserDragging: false,
        ),
        isFalse,
      );
    });
  });

  group('PlayerPresentationController route + shell (review #1)', () {
    late _AuditFakeNavigation navigation;
    late PlayerPresentationController controller;

    setUp(() {
      navigation = _AuditFakeNavigation();
      controller = PlayerPresentationController(navigation);
    });

    tearDown(() {
      controller.debugReset();
    });

    test('onRouteOpened requests shell collapse when overlay was expanded', () {
      final _AuditFakeShellHost shell = _AuditFakeShellHost();
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
    });

    test('onRouteClosed after shell expand leaves mini without route', () {
      final _AuditFakeShellHost shell = _AuditFakeShellHost();
      controller.bindShellOverlay(shell);
      controller.syncShellOverlayProgress(
        progress: 1,
        status: AnimationStatus.completed,
        isCollapsing: false,
        isUserDragging: false,
      );

      controller.onRouteOpened();
      shell.completeCollapse();
      controller.onRouteAnimationTick(1, AnimationStatus.completed);
      controller.onRouteClosed();

      expect(controller.routeOpen, isFalse);
      expect(controller.phase, PlayerPresentationPhase.mini);
      expect(controller.transitionProgress, closeTo(0, 0.001));
    });

    test('expand with shell host does not push /player', () async {
      final _AuditFakeShellHost shell = _AuditFakeShellHost();
      controller.bindShellOverlay(shell);

      unawaited(controller.expand());
      await Future<void>.delayed(Duration.zero);

      expect(navigation.pushCount, 0);
      expect(shell.expandCount, 1);
    });
  });
}

final class _AuditFakeShellHost implements PlayerShellOverlayHost {
  int expandCount = 0;
  int collapseCount = 0;

  @override
  Future<void> expand() async {
    expandCount++;
  }

  @override
  Future<void> collapse() async {
    collapseCount++;
  }

  void completeCollapse() {}
}

final class _AuditFakeNavigation implements QuranPlayerNavigation {
  int pushCount = 0;

  @override
  bool get isExpandedRouteOnStack => false;

  @override
  Future<void> pushExpanded() async {
    pushCount++;
  }

  @override
  void popExpanded() {}
}
