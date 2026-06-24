import 'package:dartz_plus/dartz_plus.dart';

import 'package:quran_sessions/src/domain/entities/quran_session.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/session_repository.dart';

class FakeSessionRepository implements SessionRepository {
  List<QuranSession> sessions = [];
  QuranSessionsFailure? failWith;

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> getSessionById(
    String sessionId,
  ) async {
    if (failWith != null) return Left(failWith!);
    final match = sessions.where((s) => s.id == sessionId).firstOrNull;
    if (match == null) return const Left(NotFoundFailure('QuranSession'));
    return Right(match);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentUpcomingSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async {
    if (failWith != null) return Left(failWith!);
    final now = DateTime.now();
    final upcoming =
        sessions
            .where((s) => s.studentId == studentId && s.startsAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return Right(SessionPage(sessions: _pageSlice(upcoming, cursor, limit)));
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentPastSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async {
    if (failWith != null) return Left(failWith!);
    final now = DateTime.now();
    final past =
        sessions
            .where((s) => s.studentId == studentId && !s.startsAt.isAfter(now))
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final page = _pageSlice(past, cursor, limit);
    final nextCursor = page.length == limit && page.isNotEmpty
        ? page.last.id
        : null;
    return Right(SessionPage(sessions: page, nextCursor: nextCursor));
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranSession>>>
  getTeacherUpcomingSessions(
    String teacherId, {
    int limit = kDefaultSessionPageSize,
  }) async {
    if (failWith != null) return Left(failWith!);
    final now = DateTime.now();
    final upcoming =
        sessions
            .where((s) => s.teacherId == teacherId && s.startsAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return Right(upcoming.take(limit).toList());
  }

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> updateNotes(
    String sessionId, {
    required String notes,
  }) async {
    if (failWith != null) return Left(failWith!);
    final idx = sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return const Left(NotFoundFailure('QuranSession'));
    final updated = QuranSession(
      id: sessions[idx].id,
      bookingId: sessions[idx].bookingId,
      teacherId: sessions[idx].teacherId,
      studentId: sessions[idx].studentId,
      startsAt: sessions[idx].startsAt,
      endsAt: sessions[idx].endsAt,
      callType: sessions[idx].callType,
      status: sessions[idx].status,
      meetingLink: sessions[idx].meetingLink,
      callRoomId: sessions[idx].callRoomId,
      notes: notes,
    );
    sessions[idx] = updated;
    return Right(updated);
  }

  List<QuranSession> _pageSlice(
    List<QuranSession> sorted,
    String? cursor,
    int limit,
  ) {
    var start = 0;
    if (cursor != null) {
      final idx = sorted.indexWhere((s) => s.id == cursor);
      start = idx < 0 ? 0 : idx + 1;
    }
    return sorted.skip(start).take(limit).toList();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
