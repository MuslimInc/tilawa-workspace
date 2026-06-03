import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'quran_player_expanded_stage_gesture_scope.dart';

/// When a stage [ScrollView] should yield vertical drags to collapse/queue
/// handlers instead of scrolling.
abstract final class QuranPlayerExpandedStageScrollDragLogic {
  QuranPlayerExpandedStageScrollDragLogic._();

  /// Downward drag at scroll top arms player collapse.
  static bool shouldLockScrollForCollapse({
    required double scrollOffset,
    required double deltaY,
  }) {
    return scrollOffset <= 0 &&
        QuranPlayerStageVerticalDragLogic.routesToPlayerCollapse(deltaY);
  }

  /// Upward drag at scroll top arms queue sheet resize.
  static bool shouldLockScrollForQueueResize({
    required double scrollOffset,
    required double deltaY,
  }) {
    return scrollOffset <= 0 &&
        QuranPlayerStageVerticalDragLogic.routesToQueueResize(deltaY);
  }

  /// Any vertical drag at scroll top that should not scroll content.
  static bool shouldLockScrollForStageDrag({
    required double scrollOffset,
    required double deltaY,
  }) {
    return shouldLockScrollForCollapse(
          scrollOffset: scrollOffset,
          deltaY: deltaY,
        ) ||
        shouldLockScrollForQueueResize(
          scrollOffset: scrollOffset,
          deltaY: deltaY,
        );
  }
}

/// [DragEndDetails] for vertical stage drags (satisfies Flutter assertions).
DragEndDetails quranPlayerExpandedStageVerticalDragEndDetails(
  Velocity tracked,
) {
  final double vy = tracked.pixelsPerSecond.dy;
  if (!vy.isFinite) {
    return DragEndDetails(primaryVelocity: 0);
  }
  return DragEndDetails(
    velocity: Velocity(pixelsPerSecond: Offset(0, vy)),
    primaryVelocity: vy,
  );
}

/// Scrollable expanded-stage chrome that forwards top-edge vertical drags.
///
/// UI-only layout shell (no bloc). Matches [TilawaMediaPlayerBar] style: app
/// wires [onVerticalDragStart], [onVerticalDragUpdate], and
/// [onVerticalDragEnd] from [QuranPlayerExpandedStageGestureScope] parents.
class QuranPlayerExpandedStageCollapsibleScrollRegion
    extends StatefulWidget {
  const QuranPlayerExpandedStageCollapsibleScrollRegion({
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.child,
    this.padding,
    this.scrollController,
    super.key,
  });

  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Optional external controller (e.g. tests); otherwise one is created.
  final ScrollController? scrollController;

  @override
  State<QuranPlayerExpandedStageCollapsibleScrollRegion> createState() =>
      _QuranPlayerExpandedStageCollapsibleScrollRegionState();
}

class _QuranPlayerExpandedStageCollapsibleScrollRegionState
    extends State<QuranPlayerExpandedStageCollapsibleScrollRegion> {
  ScrollController? _ownedScrollController;
  final VelocityTracker _velocityTracker = VelocityTracker.withKind(
    PointerDeviceKind.touch,
  );

  bool _stageDragLocked = false;
  int? _activePointer;

  ScrollController get _scrollController =>
      widget.scrollController ?? _ownedScrollController!;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    super.dispose();
  }

  ScrollPhysics get _scrollPhysics => _stageDragLocked
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics();

  void _clearStageDragState() {
    _stageDragLocked = false;
    _activePointer = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointer = event.pointer;
    _velocityTracker.addPosition(event.timeStamp, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    _velocityTracker.addPosition(event.timeStamp, event.position);

    final double offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0;
    final double deltaY = event.delta.dy;

    if (!_stageDragLocked) {
      if (!QuranPlayerExpandedStageScrollDragLogic.shouldLockScrollForStageDrag(
        scrollOffset: offset,
        deltaY: deltaY,
      )) {
        return;
      }
      _stageDragLocked = true;
      if (mounted) {
        setState(() {});
      }
      widget.onVerticalDragStart(
        DragStartDetails(
          globalPosition: event.position,
          localPosition: event.localPosition,
        ),
      );
    }

    widget.onVerticalDragUpdate(
      DragUpdateDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
        delta: Offset(0, deltaY),
      ),
    );
  }

  bool _finishPointerDrag() {
    final bool wasLocked = _stageDragLocked;
    _clearStageDragState();
    if (wasLocked && mounted) {
      setState(() {});
    }
    return wasLocked;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    final bool wasLocked = _finishPointerDrag();
    if (!wasLocked) {
      return;
    }
    widget.onVerticalDragEnd(
      quranPlayerExpandedStageVerticalDragEndDetails(
        _velocityTracker.getVelocity(),
      ),
    );
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    final bool wasLocked = _finishPointerDrag();
    if (!wasLocked) {
      return;
    }
    widget.onVerticalDragEnd(
      quranPlayerExpandedStageVerticalDragEndDetails(Velocity.zero),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget scrollChild = widget.child;
    if (widget.padding != null) {
      scrollChild = Padding(padding: widget.padding!, child: scrollChild);
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: _scrollPhysics,
        child: scrollChild,
      ),
    );
  }
}

/// Default expanded stage: header, collapsible centered chrome, controls.
class QuranPlayerExpandedStageDefaultLayout extends StatelessWidget {
  const QuranPlayerExpandedStageDefaultLayout({
    required this.header,
    required this.centeredChrome,
    required this.playbackCluster,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    super.key,
  });

  final Widget header;
  final Widget centeredChrome;
  final Widget playbackCluster;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuranPlayerExpandedStageCollapsibleScrollRegion(
                  onVerticalDragStart: onVerticalDragStart,
                  onVerticalDragUpdate: onVerticalDragUpdate,
                  onVerticalDragEnd: onVerticalDragEnd,
                  child: centeredChrome,
                ),
              ),
              playbackCluster,
            ],
          ),
        ),
      ],
    );
  }
}

/// Queue-focused stage body with scroll + pass-through spacer for empty taps.
class QuranPlayerExpandedStageQueueFocusedLayout extends StatelessWidget {
  const QuranPlayerExpandedStageQueueFocusedLayout({
    required this.maxHeight,
    required this.children,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    super.key,
  });

  final double maxHeight;
  final List<Widget> children;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: QuranPlayerExpandedStageCollapsibleScrollRegion(
              onVerticalDragStart: onVerticalDragStart,
              onVerticalDragUpdate: onVerticalDragUpdate,
              onVerticalDragEnd: onVerticalDragEnd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          Expanded(
            child: IgnorePointer(
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
