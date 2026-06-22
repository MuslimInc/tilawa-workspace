/// High-level phase grouping for session lifecycle states.
enum SessionLifecyclePhase { reservation, active, terminal }

/// Canonical lifecycle state for a Quran session aggregate.
enum SessionLifecycleStatus {
  // Reservation / payment.
  draft,
  pendingPayment,

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
}

extension SessionLifecycleStatusX on SessionLifecycleStatus {
  SessionLifecyclePhase get phase => switch (this) {
    SessionLifecycleStatus.draft ||
    SessionLifecycleStatus.pendingPayment => SessionLifecyclePhase.reservation,
    SessionLifecycleStatus.scheduled ||
    SessionLifecycleStatus.confirmed ||
    SessionLifecycleStatus.inProgress ||
    SessionLifecycleStatus.rescheduled => SessionLifecyclePhase.active,
    _ => SessionLifecyclePhase.terminal,
  };

  bool get isTerminal => phase == SessionLifecyclePhase.terminal;

  bool get isSlotBlocking =>
      phase == SessionLifecyclePhase.active ||
      this == SessionLifecycleStatus.pendingPayment;
}
