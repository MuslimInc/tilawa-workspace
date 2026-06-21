import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_price.dart';
import '../../domain/entities/session_review.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_data_source.dart';
import '../mappers/availability_mapper.dart';
import '../mappers/review_mapper.dart';
import '../mappers/teacher_mapper.dart';

import 'repository_error_mapper.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  const TeacherRepositoryImpl(this._remote);

  final TeacherRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, TeacherPage>> getTeachers({
    String? specialization,
    String? language,
    String? cursor,
  }) async {
    try {
      final result = await _remote.getTeachers(
        specialization: specialization,
        language: language,
        cursor: cursor,
      );
      return Right(
        TeacherPage(
          teachers: result.teachers.map((d) => d.toDomain()).toList(),
          nextCursor: result.nextCursor,
        ),
      );
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, QuranTeacher>> getTeacherById(
    String teacherId,
  ) async {
    try {
      final dto = await _remote.getTeacherById(teacherId);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>>
  getAvailableSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final dtos = await _remote.getAvailableSlots(
        teacherId,
        from: from,
        to: to,
      );
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionReview>>> getTeacherReviews(
    String teacherId, {
    String? cursor,
  }) async {
    try {
      final dtos = await _remote.getTeacherReviews(teacherId, cursor: cursor);
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPrice?>> resolveTeacherPrice(
    String teacherId, {
    required String countryCode,
    required String cityId,
  }) async {
    try {
      final dto = await _remote.resolveTeacherPrice(
        teacherId,
        countryCode: countryCode,
        cityId: cityId,
      );
      return Right(dto?.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
