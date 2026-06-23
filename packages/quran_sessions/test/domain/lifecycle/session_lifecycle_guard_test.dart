import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  const guard = SessionLifecycleGuard();

  group('SessionLifecycleGuard valid transitions (T-V*)', () {
    for (final testCase in _validCases) {
      test(testCase.id, () {
        final result = guard.canTransition(
          currentStatus: testCase.from,
          action: testCase.action,
          actor: testCase.actor,
          reason: testCase.reason,
        );

        result.fold((failure) => fail('expected Right but got $failure'), (
          transition,
        ) {
          check(transition.to).equals(testCase.to);
          check(transition.allowedActors).contains(testCase.actor);
          check(transition.requiresReason).equals(testCase.requiresReason);
          check(transition.sideEffects).deepEquals(testCase.sideEffects);
        });
      });
    }
  });

  group('SessionLifecycleGuard invalid transitions (T-I*)', () {
    for (final testCase in _invalidCases) {
      test(testCase.id, () {
        final result = guard.canTransition(
          currentStatus: testCase.from,
          action: testCase.action,
          actor: testCase.actor,
          reason: testCase.reason,
          isTargetSlotAvailable: testCase.isTargetSlotAvailable,
          targetSlotId: 'slot_conflict',
        );

        result.fold((failure) {
          check(failure).isA<QuranSessionsFailure>();
          check(failure.runtimeType).equals(testCase.expectedFailureType);
        }, (_) => fail('expected Left'));
      });
    }
  });

  test('blocks student cancellation within policy window by default', () {
    final now = DateTime.utc(2026, 1, 1, 10);
    final lateCancelGuard = SessionLifecycleGuard(
      now: () => now,
    );

    final result = lateCancelGuard.canTransition(
      currentStatus: SessionLifecycleStatus.scheduled,
      action: SessionAction.cancelByStudent,
      actor: ActorRole.student,
      reason: 'too late',
      sessionStartsAt: now.add(const Duration(minutes: 30)),
    );

    result.fold(
      (failure) => check(failure).isA<InvalidTransitionFailure>(),
      (_) => fail('expected Left'),
    );
  });

  test('allows disabling student cancellation window policy via config', () {
    final now = DateTime.utc(2026, 1, 1, 10);
    final guardWithDisabledWindow = SessionLifecycleGuard(
      now: () => now,
      config: const SessionLifecyclePolicyConfig(
        blockStudentCancellationWithinMinNotice: false,
      ),
    );

    final result = guardWithDisabledWindow.applyTransition(
      currentStatus: SessionLifecycleStatus.scheduled,
      action: SessionAction.cancelByStudent,
      actor: ActorRole.student,
      reason: 'allowed by market override',
      sessionStartsAt: now.add(const Duration(minutes: 30)),
    );

    result.fold(
      (failure) => fail('expected Right but got $failure'),
      (status) =>
          check(status).equals(SessionLifecycleStatus.cancelledByStudent),
    );
  });

  test('rejects non-create action without current status', () {
    final result = guard.canTransition(
      currentStatus: null,
      action: SessionAction.startSession,
      actor: ActorRole.system,
    );

    result.fold(
      (failure) {
        check(failure).isA<InvalidTransitionFailure>();
        final invalid = failure as InvalidTransitionFailure;
        check(invalid.currentStatus).isNull();
      },
      (_) => fail('expected Left'),
    );
  });
}

class _ValidCase {
  const _ValidCase({
    required this.id,
    required this.from,
    required this.action,
    required this.actor,
    required this.to,
    required this.requiresReason,
    this.reason,
    this.sideEffects = const [],
  });

  final String id;
  final SessionLifecycleStatus? from;
  final SessionAction action;
  final ActorRole actor;
  final SessionLifecycleStatus to;
  final bool requiresReason;
  final String? reason;
  final List<TransitionSideEffect> sideEffects;
}

class _InvalidCase {
  const _InvalidCase({
    required this.id,
    required this.from,
    required this.action,
    required this.actor,
    required this.expectedFailureType,
    this.reason,
    this.isTargetSlotAvailable = true,
  });

  final String id;
  final SessionLifecycleStatus from;
  final SessionAction action;
  final ActorRole actor;
  final Type expectedFailureType;
  final String? reason;
  final bool isTargetSlotAvailable;
}

const List<_ValidCase> _validCases = [
  _ValidCase(
    id: 'T-V01 createDraft ∅ -> draft by student',
    from: null,
    action: SessionAction.createDraft,
    actor: ActorRole.student,
    to: SessionLifecycleStatus.draft,
    requiresReason: false,
  ),
  _ValidCase(
    id: 'T-V02 confirmFreeBooking draft -> scheduled by student',
    from: SessionLifecycleStatus.draft,
    action: SessionAction.confirmFreeBooking,
    actor: ActorRole.student,
    to: SessionLifecycleStatus.scheduled,
    requiresReason: false,
    sideEffects: [
      TransitionSideEffect.hardLockSlot,
      TransitionSideEffect.createSessionDocument,
      TransitionSideEffect.notifyBothParties,
    ],
  ),
  _ValidCase(
    id: 'T-V03 initiatePayment draft -> pendingPayment by student',
    from: SessionLifecycleStatus.draft,
    action: SessionAction.initiatePayment,
    actor: ActorRole.student,
    to: SessionLifecycleStatus.pendingPayment,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.softHoldSlotTtl],
  ),
  _ValidCase(
    id: 'T-V04 confirmBooking pendingPayment -> scheduled by system',
    from: SessionLifecycleStatus.pendingPayment,
    action: SessionAction.confirmBooking,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.scheduled,
    requiresReason: false,
    sideEffects: [
      TransitionSideEffect.capturePayment,
      TransitionSideEffect.hardLockSlot,
      TransitionSideEffect.createSessionDocument,
      TransitionSideEffect.notifyBothParties,
    ],
  ),
  _ValidCase(
    id: 'T-V05 acknowledgeSession scheduled -> confirmed by student',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.acknowledgeSession,
    actor: ActorRole.student,
    to: SessionLifecycleStatus.confirmed,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.scheduleReminder],
  ),
  _ValidCase(
    id: 'T-V06 acknowledgeSession scheduled -> confirmed by teacher',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.acknowledgeSession,
    actor: ActorRole.teacher,
    to: SessionLifecycleStatus.confirmed,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.scheduleReminder],
  ),
  _ValidCase(
    id: 'T-V07 startSession scheduled -> inProgress by system',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.startSession,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.inProgress,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.openCallRoom],
  ),
  _ValidCase(
    id: 'T-V08 startSession confirmed -> inProgress by teacher',
    from: SessionLifecycleStatus.confirmed,
    action: SessionAction.startSession,
    actor: ActorRole.teacher,
    to: SessionLifecycleStatus.inProgress,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.openCallRoom],
  ),
  _ValidCase(
    id: 'T-V09 completeSession inProgress -> completed by system',
    from: SessionLifecycleStatus.inProgress,
    action: SessionAction.completeSession,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.completed,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.promptReview],
  ),
  _ValidCase(
    id: 'T-V10 requestReschedule scheduled -> rescheduled by student',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.requestReschedule,
    actor: ActorRole.student,
    to: SessionLifecycleStatus.rescheduled,
    reason: 'conflict',
    requiresReason: true,
    sideEffects: [TransitionSideEffect.notifyCounterparty],
  ),
  _ValidCase(
    id: 'T-V11 confirmReschedule rescheduled -> scheduled by teacher',
    from: SessionLifecycleStatus.rescheduled,
    action: SessionAction.confirmReschedule,
    actor: ActorRole.teacher,
    to: SessionLifecycleStatus.scheduled,
    reason: 'accepted',
    requiresReason: true,
    sideEffects: [
      TransitionSideEffect.swapSlotAtomically,
      TransitionSideEffect.releaseOldSlot,
      TransitionSideEffect.lockNewSlot,
    ],
  ),
  _ValidCase(
    id: 'T-V12 cancelByStudent scheduled -> cancelledByStudent by student',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.cancelByStudent,
    actor: ActorRole.student,
    to: SessionLifecycleStatus.cancelledByStudent,
    reason: 'personal',
    requiresReason: true,
    sideEffects: [TransitionSideEffect.applyCancellationPolicy],
  ),
  _ValidCase(
    id: 'T-V13 cancelByTeacher scheduled -> cancelledByTeacher by teacher',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.cancelByTeacher,
    actor: ActorRole.teacher,
    to: SessionLifecycleStatus.cancelledByTeacher,
    reason: 'illness',
    requiresReason: true,
    sideEffects: [TransitionSideEffect.autoCompensateStudent],
  ),
  _ValidCase(
    id: 'T-V14 cancelByAdmin scheduled -> cancelledByAdmin by admin',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.cancelByAdmin,
    actor: ActorRole.admin,
    to: SessionLifecycleStatus.cancelledByAdmin,
    reason: 'policy',
    requiresReason: true,
    sideEffects: [TransitionSideEffect.adminChooseCompensation],
  ),
  _ValidCase(
    id: 'T-V15 markIncomplete inProgress -> incomplete by system',
    from: SessionLifecycleStatus.inProgress,
    action: SessionAction.markIncomplete,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.incomplete,
    requiresReason: false,
  ),
  _ValidCase(
    id: 'T-V16 markTeacherNoShow scheduled -> teacherNoShow by admin',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.markTeacherNoShow,
    actor: ActorRole.admin,
    to: SessionLifecycleStatus.teacherNoShow,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.autoCompensateStudent],
  ),
  _ValidCase(
    id: 'T-V17 markStudentNoShow scheduled -> studentNoShow by teacher',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.markStudentNoShow,
    actor: ActorRole.teacher,
    to: SessionLifecycleStatus.studentNoShow,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.applyCancellationPolicy],
  ),
  _ValidCase(
    id: 'T-V18 markBothNoShow scheduled -> bothNoShow by system',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.markBothNoShow,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.bothNoShow,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.markAttendanceFromJoinLogs],
  ),
  _ValidCase(
    id: 'T-V19 issueCompensation cancelledByTeacher -> compensated by system',
    from: SessionLifecycleStatus.cancelledByTeacher,
    action: SessionAction.issueCompensation,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.compensated,
    reason: 'auto rule',
    requiresReason: true,
    sideEffects: [TransitionSideEffect.executeCompensationPolicy],
  ),
  _ValidCase(
    id: 'T-V20 openDispute completed -> disputed by student',
    from: SessionLifecycleStatus.completed,
    action: SessionAction.openDispute,
    actor: ActorRole.student,
    to: SessionLifecycleStatus.disputed,
    reason: 'dispute',
    requiresReason: true,
    sideEffects: [TransitionSideEffect.openManualReviewCase],
  ),
  _ValidCase(
    id: 'T-V21 issueRefund disputed -> refunded by admin',
    from: SessionLifecycleStatus.disputed,
    action: SessionAction.issueRefund,
    actor: ActorRole.admin,
    to: SessionLifecycleStatus.refunded,
    reason: 'refund',
    requiresReason: true,
    sideEffects: [TransitionSideEffect.executePaymentRefund],
  ),
  _ValidCase(
    id: 'T-V22 expireReservation pendingPayment -> expired by system',
    from: SessionLifecycleStatus.pendingPayment,
    action: SessionAction.expireReservation,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.expired,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.releaseSlot],
  ),
  _ValidCase(
    id: 'T-V23 rejectBooking pendingPayment -> expired by system',
    from: SessionLifecycleStatus.pendingPayment,
    action: SessionAction.rejectBooking,
    actor: ActorRole.system,
    to: SessionLifecycleStatus.expired,
    requiresReason: false,
    sideEffects: [TransitionSideEffect.voidPayment],
  ),
];

const List<_InvalidCase> _invalidCases = [
  _InvalidCase(
    id: 'T-I01 completed cancelByStudent -> invalid transition',
    from: SessionLifecycleStatus.completed,
    action: SessionAction.cancelByStudent,
    actor: ActorRole.student,
    expectedFailureType: InvalidTransitionFailure,
    reason: 'late',
  ),
  _InvalidCase(
    id: 'T-I02 cancelledByTeacher startSession -> invalid transition',
    from: SessionLifecycleStatus.cancelledByTeacher,
    action: SessionAction.startSession,
    actor: ActorRole.teacher,
    expectedFailureType: InvalidTransitionFailure,
  ),
  _InvalidCase(
    id: 'T-I03 expired confirmBooking -> invalid transition',
    from: SessionLifecycleStatus.expired,
    action: SessionAction.confirmBooking,
    actor: ActorRole.system,
    expectedFailureType: InvalidTransitionFailure,
  ),
  _InvalidCase(
    id: 'T-I04 draft completeSession -> invalid transition',
    from: SessionLifecycleStatus.draft,
    action: SessionAction.completeSession,
    actor: ActorRole.student,
    expectedFailureType: InvalidTransitionFailure,
  ),
  _InvalidCase(
    id: 'T-I05 inProgress cancelByTeacher -> invalid transition',
    from: SessionLifecycleStatus.inProgress,
    action: SessionAction.cancelByTeacher,
    actor: ActorRole.teacher,
    expectedFailureType: InvalidTransitionFailure,
    reason: 'too late',
  ),
  _InvalidCase(
    id: 'T-I06 scheduled cancelByStudent by teacher -> unauthorized',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.cancelByStudent,
    actor: ActorRole.teacher,
    expectedFailureType: UnauthorizedActorFailure,
    reason: 'not actor',
  ),
  _InvalidCase(
    id: 'T-I07 scheduled cancelByAdmin by student -> unauthorized',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.cancelByAdmin,
    actor: ActorRole.student,
    expectedFailureType: UnauthorizedActorFailure,
    reason: 'not actor',
  ),
  _InvalidCase(
    id: 'T-I08 terminal state non-remediation action -> invalid transition',
    from: SessionLifecycleStatus.refunded,
    action: SessionAction.startSession,
    actor: ActorRole.system,
    expectedFailureType: InvalidTransitionFailure,
  ),
  _InvalidCase(
    id: 'T-I09 scheduled cancelByStudent without reason -> reason required',
    from: SessionLifecycleStatus.scheduled,
    action: SessionAction.cancelByStudent,
    actor: ActorRole.student,
    expectedFailureType: ReasonRequiredFailure,
  ),
  _InvalidCase(
    id: 'T-I10 rescheduled confirmReschedule with taken slot',
    from: SessionLifecycleStatus.rescheduled,
    action: SessionAction.confirmReschedule,
    actor: ActorRole.system,
    expectedFailureType: SlotUnavailableFailure,
    reason: 'confirm',
    isTargetSlotAvailable: false,
  ),
];
