import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/teacher_application.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/teacher_application_repository.dart';
import '../datasources/teacher_application_remote_data_source.dart';
import '../exceptions/remote_exception.dart';
import '../mappers/teacher_application_mapper.dart';
import 'repository_error_mapper.dart';

class TeacherApplicationRepositoryImpl implements TeacherApplicationRepository {
  const TeacherApplicationRepositoryImpl(this._remote);

  final TeacherApplicationRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> getApplication(
    String userId,
  ) async {
    try {
      final dto = await _remote.getByUserId(userId);
      return Right(dto.toDomain());
    } on NotFoundException {
      return const Left(TeacherApplicationNotFoundFailure());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> createDraft(
    String userId,
  ) async {
    try {
      final dto = await _remote.createDraft(userId);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> saveDraft(
    TeacherApplication draft,
  ) async {
    try {
      final dto = await _remote.saveDraft(draft.toDto());
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> submit(
    TeacherApplication application,
  ) async {
    try {
      final dto = await _remote.submit(application.toDto());
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> approve({
    required String applicationId,
    required String reviewedBy,
  }) async {
    try {
      final dto = await _remote.approve(
        applicationId: applicationId,
        reviewedBy: reviewedBy,
      );
      return Right(dto.toDomain());
    } on NotFoundException {
      return const Left(TeacherApplicationNotFoundFailure());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> reject({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    try {
      final dto = await _remote.reject(
        applicationId: applicationId,
        reviewedBy: reviewedBy,
        reason: reason,
      );
      return Right(dto.toDomain());
    } on NotFoundException {
      return const Left(TeacherApplicationNotFoundFailure());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> suspend({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    try {
      final dto = await _remote.suspend(
        applicationId: applicationId,
        reviewedBy: reviewedBy,
        reason: reason,
      );
      return Right(dto.toDomain());
    } on NotFoundException {
      return const Left(TeacherApplicationNotFoundFailure());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> revoke({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    try {
      final dto = await _remote.revoke(
        applicationId: applicationId,
        reviewedBy: reviewedBy,
        reason: reason,
      );
      return Right(dto.toDomain());
    } on NotFoundException {
      return const Left(TeacherApplicationNotFoundFailure());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
