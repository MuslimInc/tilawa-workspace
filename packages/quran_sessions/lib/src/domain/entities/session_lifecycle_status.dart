/// High-level phase grouping for session lifecycle states.
enum SessionLifecyclePhase { reservation, active, terminal }

/// Canonical lifecycle state for a Quran session aggregate.
enum SessionLifecycleStatus {
  // Reservation / payment.
  draft,
  pendingPayment,
  pendingTutorApproval,

  // Active lifecycle.
  scheduled,
  confirmed,
  inProgress,
  rescheduled,

  // Terminal cancellation outcomes.
  cancelledByStudent,
  cancelledByTeacher,
  cancelledByAdmin,

  // Terminal attendance outcomes.
  teacherNoShow,
  studentNoShow,
  bothNoShow,
  incomplete,

  // Terminal successful outcome.
  completed,

  // Terminal remediation outcomes.
  disputed,
  compensated,
  refunded,
  expired,
  rejectedByTutor,
}

extension SessionLifecycleStatusX on SessionLifecycleStatus {
  SessionLifecyclePhase get phase => switch (this) {
    SessionLifecycleStatus.draft ||
    SessionLifecycleStatus.pendingPayment ||
    SessionLifecycleStatus.pendingTutorApproval =>
      SessionLifecyclePhase.reservation,
    SessionLifecycleStatus.scheduled ||
    SessionLifecycleStatus.confirmed ||
    SessionLifecycleStatus.inProgress ||
    SessionLifecycleStatus.rescheduled => SessionLifecyclePhase.active,
    _ => SessionLifecyclePhase.terminal,
  };

  bool get isTerminal => phase == SessionLifecyclePhase.terminal;

  bool get isSlotBlocking =>
      phase == SessionLifecyclePhase.active ||
      this == SessionLifecycleStatus.pendingPayment ||
      this == SessionLifecycleStatus.pendingTutorApproval;

  /// True when the participant may open the meeting link / call room.
  bool get canJoinSession => switch (this) {
    SessionLifecycleStatus.scheduled ||
    SessionLifecycleStatus.confirmed ||
    SessionLifecycleStatus.inProgress ||
    SessionLifecycleStatus.rescheduled => true,
    _ => false,
  };

  bool get isCancelled => switch (this) {
    SessionLifecycleStatus.cancelledByStudent ||
    SessionLifecycleStatus.cancelledByTeacher ||
    SessionLifecycleStatus.cancelledByAdmin => true,
    _ => false,
  };

  /// True when a participant may open a post-session dispute case.
  bool get canOpenDispute => switch (this) {
    SessionLifecycleStatus.completed ||
    SessionLifecycleStatus.cancelledByStudent ||
    SessionLifecycleStatus.cancelledByTeacher ||
    SessionLifecycleStatus.cancelledByAdmin ||
    SessionLifecycleStatus.teacherNoShow ||
    SessionLifecycleStatus.studentNoShow ||
    SessionLifecycleStatus.bothNoShow => true,
    _ => false,
  };
}
