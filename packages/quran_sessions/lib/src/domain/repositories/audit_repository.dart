import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_audit_event.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class AuditRepository {
  Future<Either<QuranSessionsFailure, void>> append(SessionAuditEvent event);

  Future<Either<QuranSessionsFailure, List<SessionAuditEvent>>> listBySessionId(
    String sessionId,
  );
}
