import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/teacher_profile.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/teacher_profile_repository.dart';
import '../datasources/teacher_profile_remote_data_source.dart';
import '../mappers/teacher_profile_mapper.dart';
import 'repository_error_mapper.dart';

class TeacherProfileRepositoryImpl implements TeacherProfileRepository {
  const TeacherProfileRepositoryImpl(this._remote);

  final TeacherProfileRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileByUserId(
    String userId,
  ) async {
    try {
      final dto = await _remote.getByUserId(userId);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileById(
    String id,
  ) async {
    try {
      final dto = await _remote.getById(id);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> createProfile(
    TeacherProfile profile,
  ) async {
    try {
      final dto = await _remote.create(profile.toDto());
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> updateProfile(
    TeacherProfile profile,
  ) async {
    try {
      final dto = await _remote.update(profile.toDto());
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> updatePublicProfile(
    TeacherProfile profile,
  ) async {
    try {
      final dto = await _remote.updatePublicProfile(profile.toDto());
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> deactivate(
    String id,
  ) async {
    try {
      final dto = await _remote.deactivate(id);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> reactivate(
    String id,
  ) async {
    try {
      final dto = await _remote.reactivate(id);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
