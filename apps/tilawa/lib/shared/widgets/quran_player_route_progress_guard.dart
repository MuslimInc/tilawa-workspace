import 'package:flutter/animation.dart';

/// Returns true when a route animation reports completed@1.0 before forward.
bool isSpuriousRouteProgressSpike({
  required bool seenForward,
  required bool seenReverse,
  required AnimationStatus status,
  required double value,
  required double currentProgress,
}) {
  return !seenForward &&
      !seenReverse &&
      status == AnimationStatus.completed &&
      value >= 0.99 &&
      currentProgress <= 0.05;
}
