import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/src/domain/entities/teacher_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/teacher_profile_repository.dart';

/// Minimal in-memory fake for [TeacherProfileRepository].
///
/// Only the methods required by tests are implemented.
class FakeTeacherProfileRepository implements TeacherProfileRepository {
  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> createProfile(
    TeacherProfile profile,
  ) async {
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> deactivate(
    String id,
  ) async {
    return const Left(NotFoundFailure('TeacherProfile'));
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileById(
    String id,
  ) async {
    return const Left(NotFoundFailure('TeacherProfile'));
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileByUserId(
    String userId,
  ) async {
    return const Left(NotFoundFailure('TeacherProfile'));
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> reactivate(
    String id,
  ) async {
    return const Left(NotFoundFailure('TeacherProfile'));
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> updateProfile(
    TeacherProfile profile,
  ) async {
    return Right(profile);
  }
}
