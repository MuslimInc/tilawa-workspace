import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_audit_event.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/audit_repository.dart';

class GetSessionTimelineUseCase {
  const GetSessionTimelineUseCase(this._auditRepository);

  final AuditRepository _auditRepository;

  Future<Either<QuranSessionsFailure, List<SessionAuditEvent>>> call(
    String sessionId,
  ) async {
    return _auditRepository.listBySessionId(sessionId);
  }
}
