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
  Future<Either<QuranSessionsFailure, List<QuranSession>>> getStudentSessions(
    String studentId,
  ) async {
    if (failWith != null) return Left(failWith!);
    return Right(sessions.where((s) => s.studentId == studentId).toList());
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranSession>>> getTeacherSessions(
    String teacherId,
  ) async {
    if (failWith != null) return Left(failWith!);
    return Right(sessions.where((s) => s.teacherId == teacherId).toList());
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
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
