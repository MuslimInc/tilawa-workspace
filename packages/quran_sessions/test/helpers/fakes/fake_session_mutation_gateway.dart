import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeSessionMutationGateway implements SessionMutationGateway {
  FakeSessionMutationGateway({this.onCreate});

  final List<String> calls = [];
  QuranSessionsFailure? failConfirmRescheduleWith;
  Future<Either<QuranSessionsFailure, SessionBookingOutcome>> Function({
    required String teacherId,
    required String studentId,
    required String slotId,
  })?
  onCreate;

  @override
  Future<Either<QuranSessionsFailure, SessionBookingOutcome>> createBooking({
    required String teacherId,
    required String studentId,
    required String slotId,
    required DateTime startsAt,
    required DateTime endsAt,
    required SessionCallType callType,
    required SessionPricingType pricingType,
    String? paymentReference,
    String? studentNote,
    String? idempotencyKey,
  }) async {
    calls.add('create:$slotId');
    if (onCreate != null) {
      return onCreate!(
        teacherId: teacherId,
        studentId: studentId,
        slotId: slotId,
      );
    }
    return Right(
      SessionBookingOutcome(
        aggregate: SessionAggregate(
          id: 'booking_1',
          teacherId: teacherId,
          studentId: studentId,
          slotId: slotId,
          startsAt: startsAt,
          pricingType: pricingType,
          lifecycleStatus: SessionLifecycleStatus.scheduled,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          paymentReference: paymentReference,
        ),
      ),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> cancelSession({
    required String bookingId,
    required String reason,
    required ActorRole actorRole,
  }) async {
    calls.add('cancel:$bookingId');
    return Right(
      SessionAggregate(
        id: bookingId,
        teacherId: 'teacher_1',
        studentId: 'student_1',
        slotId: 'slot_1',
        startsAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        pricingType: SessionPricingType.free,
        lifecycleStatus: SessionLifecycleStatus.cancelledByStudent,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, RescheduleRequestResult>>
  requestReschedule({
    required String bookingId,
    required String newSlotId,
    required DateTime newStartsAt,
    required String reason,
    required ActorRole actorRole,
  }) async => Left(NotFoundFailure('stub'));

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> confirmReschedule({
    required String requestId,
    required bool accept,
    required ActorRole actorRole,
  }) async {
    calls.add('confirmReschedule:$requestId:$accept');
    final failure = failConfirmRescheduleWith;
    if (failure != null) {
      return Left(failure);
    }
    return Right(
      SessionAggregate(
        id: 'booking_1',
        teacherId: 'teacher_1',
        studentId: 'student_1',
        slotId: accept ? 'slot_new' : 'slot_1',
        startsAt: DateTime.utc(2026, 7, 1, 10),
        pricingType: SessionPricingType.free,
        lifecycleStatus: SessionLifecycleStatus.scheduled,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> completeSession({
    required String sessionId,
    required ActorRole actorRole,
  }) async => Right(
    SessionAggregate(
      id: sessionId,
      teacherId: 'teacher_1',
      studentId: 'student_1',
      slotId: 'slot_1',
      startsAt: DateTime.now().toUtc(),
      pricingType: SessionPricingType.free,
      lifecycleStatus: SessionLifecycleStatus.completed,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> markNoShow({
    required String sessionId,
    required ActorRole actorRole,
    required String reason,
  }) async => Left(NotFoundFailure('stub'));

  @override
  Future<Either<QuranSessionsFailure, SessionReportResult>>
  reportSessionConcern({
    required SessionReportCategory category,
    required String description,
    String? bookingId,
  }) async {
    calls.add('report:${category.cfValue}');
    return const Right(SessionReportResult(reportId: 'report_fake_1'));
  }

  @override
  Future<Either<QuranSessionsFailure, SessionDisputeResult>>
  openSessionDispute({
    required String bookingId,
    required String reason,
  }) async {
    calls.add('dispute:$bookingId');
    return const Right(SessionDisputeResult(disputeId: 'dispute_fake_1'));
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>>
  respondToBookingRequest({
    required String bookingId,
    required bool accept,
    String? reason,
  }) async {
    calls.add(
      'respond:$bookingId:${accept ? 'accept' : 'reject'}:${reason ?? ''}',
    );
    return Right(
      SessionAggregate(
        id: bookingId,
        teacherId: 'teacher_1',
        studentId: 'student_1',
        slotId: 'slot_1',
        startsAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        pricingType: SessionPricingType.free,
        lifecycleStatus: accept
            ? SessionLifecycleStatus.scheduled
            : SessionLifecycleStatus.rejectedByTutor,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        rejectionReason: accept ? null : reason,
      ),
    );
  }
}
