import '../entities/session_lifecycle_status.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';
import 'session_transition.dart';
import 'transition_side_effect.dart';

/// Declarative transition map for session lifecycle actions.
class SessionTransitionTable {
  const SessionTransitionTable();

  static const Set<SessionLifecycleStatus> _allStatuses = {
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
  };

  static const List<SessionTransition> _transitions = [
    SessionTransition(
      action: SessionAction.createDraft,
      from: {},
      to: SessionLifecycleStatus.draft,
      allowedActors: {ActorRole.student},
      requiresReason: false,
    ),
    SessionTransition(
      action: SessionAction.initiatePayment,
      from: {SessionLifecycleStatus.draft},
      to: SessionLifecycleStatus.pendingPayment,
      allowedActors: {ActorRole.student},
      requiresReason: false,
      sideEffects: [TransitionSideEffect.softHoldSlotTtl],
    ),
    SessionTransition(
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
    SessionTransition(
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
    SessionTransition(
      action: SessionAction.submitBookingRequest,
      from: {SessionLifecycleStatus.draft},
      to: SessionLifecycleStatus.pendingTutorApproval,
      allowedActors: {ActorRole.student, ActorRole.system},
      requiresReason: false,
      sideEffects: [
        TransitionSideEffect.hardLockSlot,
        TransitionSideEffect.createSessionDocument,
        TransitionSideEffect.notifyBothParties,
      ],
    ),
    SessionTransition(
      action: SessionAction.acceptBookingRequest,
      from: {SessionLifecycleStatus.pendingTutorApproval},
      to: SessionLifecycleStatus.scheduled,
      allowedActors: {ActorRole.teacher},
      requiresReason: false,
      sideEffects: [TransitionSideEffect.notifyBothParties],
    ),
    SessionTransition(
      action: SessionAction.rejectBookingRequest,
      from: {SessionLifecycleStatus.pendingTutorApproval},
      to: SessionLifecycleStatus.rejectedByTutor,
      allowedActors: {ActorRole.teacher},
      requiresReason: false,
      sideEffects: [
        TransitionSideEffect.releaseSlot,
        TransitionSideEffect.notifyCounterparty,
      ],
    ),
    SessionTransition(
      action: SessionAction.expireTutorApproval,
      from: {SessionLifecycleStatus.pendingTutorApproval},
      to: SessionLifecycleStatus.expired,
      allowedActors: {ActorRole.system},
      requiresReason: false,
      sideEffects: [TransitionSideEffect.releaseSlot],
    ),
    SessionTransition(
      action: SessionAction.acknowledgeSession,
      from: {SessionLifecycleStatus.scheduled},
      to: SessionLifecycleStatus.confirmed,
      allowedActors: {ActorRole.student, ActorRole.teacher},
      requiresReason: false,
      sideEffects: [TransitionSideEffect.scheduleReminder],
    ),
    SessionTransition(
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
    SessionTransition(
      action: SessionAction.completeSession,
      from: {SessionLifecycleStatus.inProgress},
      to: SessionLifecycleStatus.completed,
      allowedActors: {
        ActorRole.system,
        ActorRole.teacher,
        ActorRole.student,
      },
      requiresReason: false,
      sideEffects: [TransitionSideEffect.promptReview],
    ),
    SessionTransition(
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
    SessionTransition(
      action: SessionAction.confirmReschedule,
      from: {SessionLifecycleStatus.rescheduled},
      to: SessionLifecycleStatus.scheduled,
      allowedActors: {
        ActorRole.student,
        ActorRole.teacher,
        ActorRole.system,
      },
      requiresReason: true,
      sideEffects: [
        TransitionSideEffect.swapSlotAtomically,
        TransitionSideEffect.releaseOldSlot,
        TransitionSideEffect.lockNewSlot,
      ],
    ),
    SessionTransition(
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
    SessionTransition(
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
    SessionTransition(
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
    SessionTransition(
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
    SessionTransition(
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
    SessionTransition(
      action: SessionAction.markStudentNoShow,
      from: {
        SessionLifecycleStatus.scheduled,
        SessionLifecycleStatus.confirmed,
        SessionLifecycleStatus.inProgress,
      },
      to: SessionLifecycleStatus.studentNoShow,
      allowedActors: {
        ActorRole.admin,
        ActorRole.system,
        ActorRole.teacher,
      },
      requiresReason: false,
      sideEffects: [TransitionSideEffect.applyCancellationPolicy],
    ),
    SessionTransition(
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
    SessionTransition(
      action: SessionAction.markIncomplete,
      from: {SessionLifecycleStatus.inProgress},
      to: SessionLifecycleStatus.incomplete,
      allowedActors: {ActorRole.system},
      requiresReason: false,
    ),
    SessionTransition(
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
      allowedActors: {
        ActorRole.student,
        ActorRole.teacher,
        ActorRole.admin,
      },
      requiresReason: true,
      sideEffects: [TransitionSideEffect.openManualReviewCase],
    ),
    SessionTransition(
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
    SessionTransition(
      action: SessionAction.issueRefund,
      from: _allStatuses,
      to: SessionLifecycleStatus.refunded,
      allowedActors: {ActorRole.admin, ActorRole.system},
      requiresReason: true,
      sideEffects: [TransitionSideEffect.executePaymentRefund],
    ),
    SessionTransition(
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
    SessionTransition(
      action: SessionAction.rejectBooking,
      from: {SessionLifecycleStatus.pendingPayment},
      to: SessionLifecycleStatus.expired,
      allowedActors: {ActorRole.system},
      requiresReason: false,
      sideEffects: [TransitionSideEffect.voidPayment],
    ),
  ];

  List<SessionTransition> all() => List.unmodifiable(_transitions);

  List<SessionTransition> forAction(SessionAction action) =>
      _transitions.where((transition) => transition.action == action).toList();
}
