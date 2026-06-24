/// Snapshot of a single participant's presence at evaluation time.
enum CallParticipantStatus {
  /// Never connected and the no-show window has not expired.
  notJoined,

  /// Never connected and the no-show window has expired.
  noShow,

  /// Connected, but the other participant is not connected yet.
  waiting,

  /// Connected while the other participant is also connected.
  connected,

  /// Dropped involuntarily after having connected.
  disconnected,

  /// Intentionally left after having connected.
  left,
}

/// Overall lifecycle state of the call.
enum QuranSessionCallStatus {
  /// No one is connected yet (and the call has not ended).
  notStarted,

  /// Exactly one participant is connected, waiting for the other.
  waitingForParticipant,

  /// Both participants are connected right now.
  inProgress,

  /// The call has ended for everyone.
  ended,
}
