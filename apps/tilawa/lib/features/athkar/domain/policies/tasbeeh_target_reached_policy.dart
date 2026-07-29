import '../entities/tasbeeh_dhikr.dart';

/// Decides when a saved-dhikr counter should pulse haptic/visual target feedback.
class TasbeehTargetReachedPolicy {
  const TasbeehTargetReachedPolicy();

  bool shouldNotifyOnIncrement({
    required TasbeehDhikr before,
    required TasbeehDhikr after,
  }) {
    return after.targetCount > 0 &&
        before.count < before.targetCount &&
        after.count >= after.targetCount;
  }
}
