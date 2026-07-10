/// Server-authoritative actions a participant may invoke on a session (Q-SR-02).
enum SessionAllowedAction {
  join,
  cancel,
  reschedule,
  reportConcern,
  openDispute,
  submitReview,
  respondToBookingRequest,
}

/// Allowed actions returned with session aggregate reads from Cloud Functions.
class SessionAllowedActions {
  const SessionAllowedActions(this.actions);

  final Set<SessionAllowedAction> actions;

  bool can(SessionAllowedAction action) => actions.contains(action);

  static const empty = SessionAllowedActions({});
}
