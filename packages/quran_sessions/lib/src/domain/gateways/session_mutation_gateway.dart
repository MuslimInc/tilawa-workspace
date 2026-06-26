import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_booking_outcome.dart';
import '../entities/session_call_type.dart';
import '../entities/session_pricing_type.dart';
import '../entities/session_report_category.dart';
import '../failures/quran_sessions_failure.dart';
import '../value_objects/actor_role.dart';

/// Server-orchestrated lifecycle mutations via callable Cloud Functions.
///
/// Host apps implement this gateway; domain use cases delegate persistence
/// side effects here instead of writing Firestore directly.
abstract interface class SessionMutationGateway {
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
  });

  Future<Either<QuranSessionsFailure, SessionAggregate>> cancelSession({
    required String bookingId,
    required String reason,
    required ActorRole actorRole,
  });

  Future<Either<QuranSessionsFailure, RescheduleRequestResult>>
  requestReschedule({
    required String bookingId,
    required String newSlotId,
    required DateTime newStartsAt,
    required String reason,
    required ActorRole actorRole,
  });

  Future<Either<QuranSessionsFailure, SessionAggregate>> confirmReschedule({
    required String requestId,
    required bool accept,
    required ActorRole actorRole,
  });

  Future<Either<QuranSessionsFailure, SessionAggregate>> completeSession({
    required String sessionId,
    required ActorRole actorRole,
  });

  Future<Either<QuranSessionsFailure, SessionAggregate>> markNoShow({
    required String sessionId,
    required ActorRole actorRole,
    required String reason,
  });

  Future<Either<QuranSessionsFailure, SessionReportResult>>
  reportSessionConcern({
    required SessionReportCategory category,
    required String description,
    String? bookingId,
  });

  Future<Either<QuranSessionsFailure, SessionDisputeResult>>
  openSessionDispute({
    required String bookingId,
    required String reason,
  });

  Future<Either<QuranSessionsFailure, SessionAggregate>>
  respondToBookingRequest({
    required String bookingId,
    required bool accept,
    String? reason,
  });
}

class SessionDisputeResult {
  const SessionDisputeResult({required this.disputeId});

  final String disputeId;
}

class SessionReportResult {
  const SessionReportResult({required this.reportId});

  final String reportId;
}

class RescheduleRequestResult {
  const RescheduleRequestResult({
    required this.requestId,
    required this.aggregate,
  });

  final String requestId;
  final SessionAggregate aggregate;
}
