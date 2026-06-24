import 'package:dartz_plus/dartz_plus.dart';

import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

class FakeMvpSessionRepository implements SessionRepository {
  FakeMvpSessionRepository(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> getSessionById(
    String sessionId,
  ) async {
    final match = _store.sessions.where((s) => s.id == sessionId).firstOrNull;
    if (match == null) return const Left(NotFoundFailure('QuranSession'));
    return Right(match);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentUpcomingSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async {
    final now = DateTime.now();
    final upcoming = _store.sessions
        .where((s) => s.studentId == studentId && s.startsAt.isAfter(now))
        .toList();
    return Right(SessionPage(sessions: upcoming.take(limit).toList()));
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentPastSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async {
    final now = DateTime.now();
    final past = _store.sessions
        .where((s) => s.studentId == studentId && !s.startsAt.isAfter(now))
        .toList();
    return Right(SessionPage(sessions: past.take(limit).toList()));
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranSession>>>
  getTeacherUpcomingSessions(
    String teacherId, {
    int limit = kDefaultSessionPageSize,
  }) async {
    final now = DateTime.now();
    return Right(
      _store.sessions
          .where((s) => s.teacherId == teacherId && s.startsAt.isAfter(now))
          .take(limit)
          .toList(),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> updateNotes(
    String sessionId, {
    required String notes,
  }) async {
    final idx = _store.sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return const Left(NotFoundFailure('QuranSession'));
    final s = _store.sessions[idx];
    final updated = QuranSession(
      id: s.id,
      bookingId: s.bookingId,
      teacherId: s.teacherId,
      studentId: s.studentId,
      startsAt: s.startsAt,
      endsAt: s.endsAt,
      callType: s.callType,
      status: s.status,
      meetingLink: s.meetingLink,
      callRoomId: s.callRoomId,
      notes: notes,
    );
    _store.sessions[idx] = updated;
    return Right(updated);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
