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
  Future<Either<QuranSessionsFailure, List<QuranSession>>> getStudentSessions(
    String studentId,
  ) async {
    try {
      final dtos = await _remote.getStudentSessions(studentId);
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranSession>>> getTeacherSessions(
    String teacherId,
  ) async {
    try {
      final dtos = await _remote.getTeacherSessions(teacherId);
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
