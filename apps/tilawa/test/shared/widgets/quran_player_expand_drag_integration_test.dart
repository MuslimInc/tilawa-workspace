import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_gesture_policy.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

/// Minimal shell-footer drag harness mirroring [QuranPlayerWidget] apply path.
class _ShellExpandDragHarness extends StatefulWidget {
  const _ShellExpandDragHarness({
    required this.viewportHeight,
    required this.anchorHeight,
  });

  final double viewportHeight;
  final double anchorHeight;

  @override
  State<_ShellExpandDragHarness> createState() =>
      _ShellExpandDragHarnessState();
}

class _ShellExpandDragHarnessState extends State<_ShellExpandDragHarness>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pointerRouteAttached = false;
  int? _activePointerId;

  double get progress => _controller.value;

  bool get pointerRouteAttached => _pointerRouteAttached;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void beginDrag() {
    _controller.stop(canceled: false);
    _pointerRouteAttached = true;
    _activePointerId = null;
  }

  void endDrag() {
    _pointerRouteAttached = false;
    _activePointerId = null;
  }

  /// Simulates orphaned pointer-up when the footer recognizer never fires end.
  void finishOrphanedPointerDrag({
    double progressThreshold = 0.45,
    double velocityThreshold = 500,
  }) {
    if (!_pointerRouteAttached) {
      return;
    }
    _pointerRouteAttached = false;
    final PlayerExpandSnapTarget target =
        QuranPlayerExpandPhysics.resolveSnap(
      progress: _controller.value,
      primaryVelocity: 0,
      progressThreshold: progressThreshold,
      velocityThreshold: velocityThreshold,
    );
    final double targetValue =
        target == PlayerExpandSnapTarget.expand ? 1.0 : 0.0;
    _controller.value = targetValue;
    _activePointerId = null;
  }

  void applyDrag(
    double dragPixels, {
    required QuranPlayerExpandDragChannel channel,
    int pointerId = 1,
  }) {
    if (channel == QuranPlayerExpandDragChannel.pointerRoute) {
      if (!QuranPlayerExpandGesturePolicy.shouldPointerRouteApplyMove(
        isUserDraggingExpand: _pointerRouteAttached,
        activePointerId: _activePointerId,
        eventPointerId: pointerId,
      )) {
        return;
      }
      _activePointerId ??= pointerId;
    }

    if (!QuranPlayerExpandGesturePolicy.shouldApplyRecognizerDragDelta(
      pointerRouteAttached: _pointerRouteAttached,
      channel: channel,
    )) {
      return;
    }

    final double travel = (widget.viewportHeight - widget.anchorHeight).clamp(
      1.0,
      double.infinity,
    );
    _controller.value = QuranPlayerExpandPhysics.applyDragDelta(
      current: _controller.value,
      dragPixels: dragPixels,
      travelPixels: travel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text('progress:${_controller.value.toStringAsFixed(3)}');
  }
}

void main() {
  group('Shell expand drag integration (audit harness)', () {
    testWidgets('recognizer deltas ignored while pointer route is active', (
      tester,
    ) async {
      const double travel = 800 - 108;
      const double delta = -travel * 0.2;

      late _ShellExpandDragHarnessState state;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 800,
            child: _ShellExpandDragHarness(
              viewportHeight: 800,
              anchorHeight: 108,
            ),
          ),
        ),
      );
      state = tester.state(find.byType(_ShellExpandDragHarness));

      state.beginDrag();
      expect(state.progress, 0);

      state.applyDrag(
        delta,
        channel: QuranPlayerExpandDragChannel.footerRecognizer,
      );
      state.applyDrag(
        delta,
        channel: QuranPlayerExpandDragChannel.expandedRecognizer,
      );
      expect(state.progress, 0);

      state.applyDrag(
        delta,
        channel: QuranPlayerExpandDragChannel.pointerRoute,
      );
      expect(state.progress, closeTo(0.2, 0.001));
    });

    testWidgets('pointer route ignores secondary pointer moves', (
      tester,
    ) async {
      const double travel = 800 - 108;
      const double delta = -travel * 0.1;

      late _ShellExpandDragHarnessState state;
      await tester.pumpWidget(
        MaterialApp(
          home: _ShellExpandDragHarness(
            viewportHeight: 800,
            anchorHeight: 108,
          ),
        ),
      );
      state = tester.state(find.byType(_ShellExpandDragHarness));

      state.beginDrag();
      state.applyDrag(
        delta,
        channel: QuranPlayerExpandDragChannel.pointerRoute,
        pointerId: 7,
      );
      expect(state.progress, closeTo(0.1, 0.001));

      state.applyDrag(
        delta,
        channel: QuranPlayerExpandDragChannel.pointerRoute,
        pointerId: 99,
      );
      expect(state.progress, closeTo(0.1, 0.001));
    });

    testWidgets('orphaned pointer-up snaps expand at mid progress', (
      tester,
    ) async {
      const double travel = 800 - 108;
      const double delta = -travel * 0.5;

      late _ShellExpandDragHarnessState state;
      await tester.pumpWidget(
        MaterialApp(
          home: _ShellExpandDragHarness(
            viewportHeight: 800,
            anchorHeight: 108,
          ),
        ),
      );
      state = tester.state(find.byType(_ShellExpandDragHarness));

      state.beginDrag();
      state.applyDrag(
        delta,
        channel: QuranPlayerExpandDragChannel.pointerRoute,
        pointerId: 11,
      );
      expect(state.progress, closeTo(0.5, 0.001));

      state.finishOrphanedPointerDrag();
      expect(state.progress, 1);
      expect(state.pointerRouteAttached, isFalse);
    });

    testWidgets('orphaned pointer-up snaps collapse at low progress', (
      tester,
    ) async {
      const double travel = 800 - 108;
      const double delta = -travel * 0.2;

      late _ShellExpandDragHarnessState state;
      await tester.pumpWidget(
        MaterialApp(
          home: _ShellExpandDragHarness(
            viewportHeight: 800,
            anchorHeight: 108,
          ),
        ),
      );
      state = tester.state(find.byType(_ShellExpandDragHarness));

      state.beginDrag();
      state.applyDrag(
        delta,
        channel: QuranPlayerExpandDragChannel.pointerRoute,
      );
      expect(state.progress, closeTo(0.2, 0.001));

      state.finishOrphanedPointerDrag();
      expect(state.progress, 0);
    });

    testWidgets('collapse-biased metrics during downward interactive drag', (
      tester,
    ) async {
      final PlayerExpandTransitionMetrics expandForward =
          PlayerExpandTransitionMetrics.compute(
            progress: 0.70,
            miniPlayerHeight: 76,
            interactiveDrag: true,
            collapseBiased: false,
          );
      final PlayerExpandTransitionMetrics collapseDrag =
          PlayerExpandTransitionMetrics.compute(
            progress: 0.70,
            miniPlayerHeight: 76,
            interactiveDrag: true,
            collapseBiased: true,
            interactiveCollapseAnchor: 1,
          );

      expect(expandForward.showMiniPlayer, isFalse);
      expect(collapseDrag.showMiniPlayer, isTrue);
    });
  });
}
