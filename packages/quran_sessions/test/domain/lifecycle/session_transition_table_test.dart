import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  const table = SessionTransitionTable();

  group('SessionLifecycleStatus helpers', () {
    test('maps statuses to expected phases', () {
      check(SessionLifecycleStatus.draft.phase).equals(
        SessionLifecyclePhase.reservation,
      );
      check(SessionLifecycleStatus.pendingPayment.phase).equals(
        SessionLifecyclePhase.reservation,
      );
      check(SessionLifecycleStatus.scheduled.phase).equals(
        SessionLifecyclePhase.active,
      );
      check(SessionLifecycleStatus.inProgress.phase).equals(
        SessionLifecyclePhase.active,
      );
      check(SessionLifecycleStatus.completed.phase).equals(
        SessionLifecyclePhase.terminal,
      );
      check(SessionLifecycleStatus.expired.phase).equals(
        SessionLifecyclePhase.terminal,
      );
    });

    test('flags terminal statuses', () {
      check(SessionLifecycleStatus.completed.isTerminal).isTrue();
      check(SessionLifecycleStatus.disputed.isTerminal).isTrue();
      check(SessionLifecycleStatus.scheduled.isTerminal).isFalse();
    });

    test('flags slot-blocking statuses', () {
      check(SessionLifecycleStatus.pendingPayment.isSlotBlocking).isTrue();
      check(SessionLifecycleStatus.scheduled.isSlotBlocking).isTrue();
      check(SessionLifecycleStatus.completed.isSlotBlocking).isFalse();
    });
  });

  group('SessionTransition value object', () {
    test('supportsFrom checks current status membership', () {
      const transition = SessionTransition(
        action: SessionAction.startSession,
        from: {
          SessionLifecycleStatus.scheduled,
          SessionLifecycleStatus.confirmed,
        },
        to: SessionLifecycleStatus.inProgress,
        allowedActors: {ActorRole.system},
        requiresReason: false,
      );

      check(transition.supportsFrom(SessionLifecycleStatus.scheduled)).isTrue();
      check(transition.supportsFrom(SessionLifecycleStatus.confirmed)).isTrue();
      check(
        transition.supportsFrom(SessionLifecycleStatus.completed),
      ).isFalse();
      check(transition.supportsFrom(null)).isFalse();
    });

    test('equatable compares transition instances by value', () {
      final first = SessionTransition(
        action: SessionAction.expireReservation,
        from: {
          SessionLifecycleStatus.draft,
          SessionLifecycleStatus.pendingPayment,
        },
        to: SessionLifecycleStatus.expired,
        allowedActors: {ActorRole.system},
        requiresReason: false,
        sideEffects: [TransitionSideEffect.releaseSlot],
      );
      final second = SessionTransition(
        action: SessionAction.expireReservation,
        from: {
          SessionLifecycleStatus.draft,
          SessionLifecycleStatus.pendingPayment,
        },
        to: SessionLifecycleStatus.expired,
        allowedActors: {ActorRole.system},
        requiresReason: false,
        sideEffects: [TransitionSideEffect.releaseSlot],
      );

      check(first).equals(second);
      check(first.props).deepEquals([
        SessionAction.expireReservation,
        {
          SessionLifecycleStatus.draft,
          SessionLifecycleStatus.pendingPayment,
        },
        SessionLifecycleStatus.expired,
        {ActorRole.system},
        false,
        [TransitionSideEffect.releaseSlot],
      ]);
    });
  });

  group('SessionTransitionTable', () {
    test('contains one declarative rule per action', () {
      final transitions = table.all();
      check(transitions.length).equals(SessionAction.values.length);
      check(transitions.map((it) => it.action).toSet()).deepEquals(
        SessionAction.values.toSet(),
      );
    });

    for (final expected in _expectedRows) {
      test('declares ${expected.action.name} metadata', () {
        final transition = table.forAction(expected.action).single;
        check(transition.from).deepEquals(expected.from);
        check(transition.to).equals(expected.to);
        check(transition.allowedActors).deepEquals(expected.allowedActors);
        check(transition.requiresReason).equals(expected.requiresReason);
        check(transition.sideEffects).deepEquals(expected.sideEffects);
      });
    }
  });
}

class _ExpectedRow {
  const _ExpectedRow({
    required this.action,
    required this.from,
    required this.to,
    required this.allowedActors,
    required this.requiresReason,
    this.sideEffects = const [],
  });

  final SessionAction action;
  final Set<SessionLifecycleStatus> from;
  final SessionLifecycleStatus to;
  final Set<ActorRole> allowedActors;
  final bool requiresReason;
  final List<TransitionSideEffect> sideEffects;
}

const List<_ExpectedRow> _expectedRows = [
  _ExpectedRow(
    action: SessionAction.createDraft,
    from: {},
    to: SessionLifecycleStatus.draft,
    allowedActors: {ActorRole.student},
    requiresReason: false,
  ),
  _ExpectedRow(
    action: SessionAction.initiatePayment,
    from: {SessionLifecycleStatus.draft},
    to: SessionLifecycleStatus.pendingPayment,
    allowedActors: {ActorRole.student},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.softHoldSlotTtl],
  ),
  _ExpectedRow(
    action: SessionAction.confirmBooking,
    from: {SessionLifecycleStatus.pendingPayment},
    to: SessionLifecycleStatus.scheduled,
    allowedActors: {ActorRole.system},
    requiresReason: false,
    sideEffects: [
      TransitionSideEffect.capturePayment,
      TransitionSideEffect.hardLockSlot,
      TransitionSideEffect.createSessionDocument,
      TransitionSideEffect.notifyBothParties,
    ],
  ),
  _ExpectedRow(
    action: SessionAction.confirmFreeBooking,
    from: {SessionLifecycleStatus.draft},
    to: SessionLifecycleStatus.scheduled,
    allowedActors: {ActorRole.student, ActorRole.system},
    requiresReason: false,
    sideEffects: [
      TransitionSideEffect.hardLockSlot,
      TransitionSideEffect.createSessionDocument,
      TransitionSideEffect.notifyBothParties,
    ],
  ),
  _ExpectedRow(
    action: SessionAction.acknowledgeSession,
    from: {SessionLifecycleStatus.scheduled},
    to: SessionLifecycleStatus.confirmed,
    allowedActors: {ActorRole.student, ActorRole.teacher},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.scheduleReminder],
  ),
  _ExpectedRow(
    action: SessionAction.startSession,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
    },
    to: SessionLifecycleStatus.inProgress,
    allowedActors: {ActorRole.system, ActorRole.teacher},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.openCallRoom],
  ),
  _ExpectedRow(
    action: SessionAction.completeSession,
    from: {SessionLifecycleStatus.inProgress},
    to: SessionLifecycleStatus.completed,
    allowedActors: {ActorRole.system, ActorRole.teacher, ActorRole.student},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.promptReview],
  ),
  _ExpectedRow(
    action: SessionAction.requestReschedule,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
    },
    to: SessionLifecycleStatus.rescheduled,
    allowedActors: {ActorRole.student, ActorRole.teacher},
    requiresReason: true,
    sideEffects: [TransitionSideEffect.notifyCounterparty],
  ),
  _ExpectedRow(
    action: SessionAction.confirmReschedule,
    from: {SessionLifecycleStatus.rescheduled},
    to: SessionLifecycleStatus.scheduled,
    allowedActors: {ActorRole.student, ActorRole.teacher, ActorRole.system},
    requiresReason: true,
    sideEffects: [
      TransitionSideEffect.swapSlotAtomically,
      TransitionSideEffect.releaseOldSlot,
      TransitionSideEffect.lockNewSlot,
    ],
  ),
  _ExpectedRow(
    action: SessionAction.adminForceReschedule,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
    },
    to: SessionLifecycleStatus.scheduled,
    allowedActors: {ActorRole.admin},
    requiresReason: true,
    sideEffects: [
      TransitionSideEffect.appendAuditTrail,
      TransitionSideEffect.notifyBothParties,
    ],
  ),
  _ExpectedRow(
    action: SessionAction.cancelByStudent,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
      SessionLifecycleStatus.pendingPayment,
      SessionLifecycleStatus.pendingTutorApproval,
    },
    to: SessionLifecycleStatus.cancelledByStudent,
    allowedActors: {ActorRole.student},
    requiresReason: true,
    sideEffects: [TransitionSideEffect.applyCancellationPolicy],
  ),
  _ExpectedRow(
    action: SessionAction.cancelByTeacher,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
    },
    to: SessionLifecycleStatus.cancelledByTeacher,
    allowedActors: {ActorRole.teacher},
    requiresReason: true,
    sideEffects: [TransitionSideEffect.autoCompensateStudent],
  ),
  _ExpectedRow(
    action: SessionAction.cancelByAdmin,
    from: {
      SessionLifecycleStatus.draft,
      SessionLifecycleStatus.pendingPayment,
      SessionLifecycleStatus.pendingTutorApproval,
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
      SessionLifecycleStatus.inProgress,
      SessionLifecycleStatus.rescheduled,
    },
    to: SessionLifecycleStatus.cancelledByAdmin,
    allowedActors: {ActorRole.admin},
    requiresReason: true,
    sideEffects: [TransitionSideEffect.adminChooseCompensation],
  ),
  _ExpectedRow(
    action: SessionAction.markTeacherNoShow,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
      SessionLifecycleStatus.inProgress,
    },
    to: SessionLifecycleStatus.teacherNoShow,
    allowedActors: {ActorRole.admin, ActorRole.system},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.autoCompensateStudent],
  ),
  _ExpectedRow(
    action: SessionAction.markStudentNoShow,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
      SessionLifecycleStatus.inProgress,
    },
    to: SessionLifecycleStatus.studentNoShow,
    allowedActors: {ActorRole.admin, ActorRole.system, ActorRole.teacher},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.applyCancellationPolicy],
  ),
  _ExpectedRow(
    action: SessionAction.markBothNoShow,
    from: {
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
      SessionLifecycleStatus.inProgress,
    },
    to: SessionLifecycleStatus.bothNoShow,
    allowedActors: {ActorRole.system},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.markAttendanceFromJoinLogs],
  ),
  _ExpectedRow(
    action: SessionAction.markIncomplete,
    from: {SessionLifecycleStatus.inProgress},
    to: SessionLifecycleStatus.incomplete,
    allowedActors: {ActorRole.system},
    requiresReason: false,
  ),
  _ExpectedRow(
    action: SessionAction.openDispute,
    from: {
      SessionLifecycleStatus.completed,
      SessionLifecycleStatus.cancelledByStudent,
      SessionLifecycleStatus.cancelledByTeacher,
      SessionLifecycleStatus.cancelledByAdmin,
      SessionLifecycleStatus.teacherNoShow,
      SessionLifecycleStatus.studentNoShow,
      SessionLifecycleStatus.bothNoShow,
    },
    to: SessionLifecycleStatus.disputed,
    allowedActors: {ActorRole.student, ActorRole.teacher, ActorRole.admin},
    requiresReason: true,
    sideEffects: [TransitionSideEffect.openManualReviewCase],
  ),
  _ExpectedRow(
    action: SessionAction.issueCompensation,
    from: {
      SessionLifecycleStatus.disputed,
      SessionLifecycleStatus.cancelledByTeacher,
      SessionLifecycleStatus.teacherNoShow,
    },
    to: SessionLifecycleStatus.compensated,
    allowedActors: {ActorRole.admin, ActorRole.system},
    requiresReason: true,
    sideEffects: [TransitionSideEffect.executeCompensationPolicy],
  ),
  _ExpectedRow(
    action: SessionAction.issueRefund,
    from: {
      SessionLifecycleStatus.draft,
      SessionLifecycleStatus.pendingPayment,
      SessionLifecycleStatus.pendingTutorApproval,
      SessionLifecycleStatus.scheduled,
      SessionLifecycleStatus.confirmed,
      SessionLifecycleStatus.inProgress,
      SessionLifecycleStatus.rescheduled,
      SessionLifecycleStatus.cancelledByStudent,
      SessionLifecycleStatus.cancelledByTeacher,
      SessionLifecycleStatus.cancelledByAdmin,
      SessionLifecycleStatus.teacherNoShow,
      SessionLifecycleStatus.studentNoShow,
      SessionLifecycleStatus.bothNoShow,
      SessionLifecycleStatus.incomplete,
      SessionLifecycleStatus.completed,
      SessionLifecycleStatus.disputed,
      SessionLifecycleStatus.compensated,
      SessionLifecycleStatus.refunded,
      SessionLifecycleStatus.expired,
      SessionLifecycleStatus.rejectedByTutor,
    },
    to: SessionLifecycleStatus.refunded,
    allowedActors: {ActorRole.admin, ActorRole.system},
    requiresReason: true,
    sideEffects: [TransitionSideEffect.executePaymentRefund],
  ),
  _ExpectedRow(
    action: SessionAction.expireReservation,
    from: {
      SessionLifecycleStatus.draft,
      SessionLifecycleStatus.pendingPayment,
    },
    to: SessionLifecycleStatus.expired,
    allowedActors: {ActorRole.system},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.releaseSlot],
  ),
  _ExpectedRow(
    action: SessionAction.rejectBooking,
    from: {SessionLifecycleStatus.pendingPayment},
    to: SessionLifecycleStatus.expired,
    allowedActors: {ActorRole.system},
    requiresReason: false,
    sideEffects: [TransitionSideEffect.voidPayment],
  ),
];
