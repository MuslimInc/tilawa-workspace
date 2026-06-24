import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_session.dart';
import '../failures/quran_sessions_failure.dart';

/// Default page size for student/teacher session list queries.
const int kDefaultSessionPageSize = 30;

/// Paginated session list result; [nextCursor] is the last session doc id.
class SessionPage {
  const SessionPage({
    required this.sessions,
    this.nextCursor,
  });

  final List<QuranSession> sessions;

  /// Opaque cursor for the next page; null when no more results.
  final String? nextCursor;
}

abstract interface class SessionRepository {
  Future<Either<QuranSessionsFailure, QuranSession>> getSessionById(
    String sessionId,
  );

  /// Upcoming sessions (`startsAt >= now`), ascending, capped at [limit].
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentUpcomingSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  });

  /// Past sessions (`startsAt < now`), descending, paginated.
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentPastSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  });

  /// Upcoming teacher sessions only — dashboard does not need full history.
  Future<Either<QuranSessionsFailure, List<QuranSession>>>
  getTeacherUpcomingSessions(
    String teacherId, {
    int limit = kDefaultSessionPageSize,
  });

  /// Updates session notes (student or teacher).
  Future<Either<QuranSessionsFailure, QuranSession>> updateNotes(
    String sessionId, {
    required String notes,
  });
}
