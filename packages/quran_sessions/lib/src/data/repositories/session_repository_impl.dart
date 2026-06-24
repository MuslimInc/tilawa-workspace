import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_data_source.dart';
import '../mappers/session_mapper.dart';
import 'repository_error_mapper.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._remote);

  final SessionRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> getSessionById(
    String sessionId,
  ) async {
    try {
      final dto = await _remote.getSessionById(sessionId);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentUpcomingSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async {
    try {
      final page = await _remote.getStudentUpcomingSessions(
        studentId,
        cursor: cursor,
        limit: limit,
      );
      return Right(
        SessionPage(
          sessions: page.sessions.map((d) => d.toDomain()).toList(),
          nextCursor: page.nextCursor,
        ),
      );
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentPastSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async {
    try {
      final page = await _remote.getStudentPastSessions(
        studentId,
        cursor: cursor,
        limit: limit,
      );
      return Right(
        SessionPage(
          sessions: page.sessions.map((d) => d.toDomain()).toList(),
          nextCursor: page.nextCursor,
        ),
      );
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranSession>>>
  getTeacherUpcomingSessions(
    String teacherId, {
    int limit = kDefaultSessionPageSize,
  }) async {
    try {
      final dtos = await _remote.getTeacherUpcomingSessions(
        teacherId,
        limit: limit,
      );
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> updateNotes(
    String sessionId, {
    required String notes,
  }) async {
    try {
      final dto = await _remote.updateNotes(sessionId, notes: notes);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
