import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_audit_event.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class AuditRepository {
  Future<Either<QuranSessionsFailure, void>> append(SessionAuditEvent event);

  /// Loads audit events for a booking aggregate.
  ///
  /// [bookingId] is the `quran_bookings` document id. [sessionId], when set, is
  /// the linked `quran_sessions` document id (may differ from [bookingId]).
  Future<Either<QuranSessionsFailure, List<SessionAuditEvent>>>
  listForAggregate({
    required String bookingId,
    String? sessionId,
  });
}
