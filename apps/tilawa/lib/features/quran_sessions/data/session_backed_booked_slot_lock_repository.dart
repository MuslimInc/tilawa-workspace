import 'package:dartz_plus/dartz_plus.dart';

import 'package:quran_sessions/quran_sessions.dart';

/// MVP / test adapter: derives booked starts from in-memory sessions.
class SessionBackedBookedSlotLockRepository
    implements BookedSlotLockRepository {
  const SessionBackedBookedSlotLockRepository(this._sessions);

  final SessionRepository _sessions;

  @override
  Future<Either<QuranSessionsFailure, Set<DateTime>>> getActiveBookedStarts(
    String teacherProfileId, {
    required DateTime windowStart,
    required DateTime windowEnd,
    DateTime? now,
  }) async {
    final sessionsResult = await _sessions.getTeacherSessions(teacherProfileId);
    return sessionsResult.map(
      (sessions) => collectBookedSlotStarts(
        sessions,
        windowStart: windowStart,
        windowEnd: windowEnd,
      ),
    );
  }
}
