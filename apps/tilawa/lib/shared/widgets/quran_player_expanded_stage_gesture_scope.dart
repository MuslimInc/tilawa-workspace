import 'package:flutter/material.dart';

/// Tap and vertical-drag on empty expanded-player stage chrome.
///
/// Paints a full-size gesture layer behind [child]; interactive controls on top
/// still win the arena. Not used on the queue [DraggableScrollableSheet].
class QuranPlayerExpandedStageGestureScope extends StatelessWidget {
  const QuranPlayerExpandedStageGestureScope({
    required this.onCollapse,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.child,
    super.key,
  });

  final VoidCallback onCollapse;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            onTap: onCollapse,
            onVerticalDragStart: onVerticalDragStart,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Stage vertical-drag routing for shell expand collapse vs queue resize.
abstract final class QuranPlayerStageVerticalDragLogic {
  QuranPlayerStageVerticalDragLogic._();

  /// First downward [deltaY] should arm player collapse drag.
  static bool shouldStartCollapseDrag({
    required double deltaY,
    required bool collapseDragActive,
  }) {
    return deltaY > 0 && !collapseDragActive;
  }

  /// Downward deltas go to player collapse; upward to queue sheet (when armed).
  static bool routesToPlayerCollapse(double deltaY) => deltaY > 0;

  static bool routesToQueueResize(double deltaY) => deltaY < 0;
}

/// Applies [QuranPlayerStageVerticalDragLogic] for organism stage drags.
void applyQuranPlayerStageVerticalDragDelta({
  required double deltaY,
  required bool collapseDragActive,
  required void Function() onArmCollapseDrag,
  required void Function(double deltaY) onPlayerCollapseDragUpdate,
  required void Function(double deltaY) onQueueSheetDragUp,
}) {
  if (QuranPlayerStageVerticalDragLogic.routesToPlayerCollapse(deltaY)) {
    if (QuranPlayerStageVerticalDragLogic.shouldStartCollapseDrag(
      deltaY: deltaY,
      collapseDragActive: collapseDragActive,
    )) {
      onArmCollapseDrag();
    }
    onPlayerCollapseDragUpdate(deltaY);
    return;
  }
  if (QuranPlayerStageVerticalDragLogic.routesToQueueResize(deltaY)) {
    onQueueSheetDragUp(deltaY);
  }
}
