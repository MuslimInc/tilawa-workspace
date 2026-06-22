import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_call_type.dart';
import '../entities/session_pricing_type.dart';
import '../failures/quran_sessions_failure.dart';
import '../value_objects/actor_role.dart';

/// Server-orchestrated lifecycle mutations via callable Cloud Functions.
///
/// Host apps implement this gateway; domain use cases delegate persistence
/// side effects here instead of writing Firestore directly.
abstract interface class SessionMutationGateway {
  Future<Either<QuranSessionsFailure, SessionAggregate>> createBooking({
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
}

class RescheduleRequestResult {
  const RescheduleRequestResult({
    required this.requestId,
    required this.aggregate,
  });

  final String requestId;
  final SessionAggregate aggregate;
}
