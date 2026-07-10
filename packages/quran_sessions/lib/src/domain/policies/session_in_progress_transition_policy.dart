/// Rules for system `inProgress` transition (Q-SL-03).
abstract final class SessionInProgressTransitionPolicy {
  /// True when `startsAt` has passed and at least one join event was logged.
  static bool shouldTransitionToInProgress({
    required DateTime startsAt,
    required DateTime now,
    required bool hasJoinEventAtOrAfterStart,
  }) {
    if (!hasJoinEventAtOrAfterStart) return false;
    return !now.isBefore(startsAt);
  }
}
