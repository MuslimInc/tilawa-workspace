import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeAuditRepository implements AuditRepository {
  QuranSessionsFailure? failWith;
  final List<SessionAuditEvent> events = [];

  @override
  Future<Either<QuranSessionsFailure, void>> append(
    SessionAuditEvent event,
  ) async {
    if (failWith != null) return Left(failWith!);
    events.add(event);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionAuditEvent>>> listBySessionId(
    String sessionId,
  ) async {
    if (failWith != null) return Left(failWith!);
    return Right(
      events
          .where((event) => event.sessionId == sessionId)
          .toList(growable: false),
    );
  }
}
