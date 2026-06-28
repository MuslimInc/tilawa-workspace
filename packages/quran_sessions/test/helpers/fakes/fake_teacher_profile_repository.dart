import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/src/domain/entities/teacher_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/teacher_profile_repository.dart';

/// Minimal in-memory fake for [TeacherProfileRepository].
class FakeTeacherProfileRepository implements TeacherProfileRepository {
  FakeTeacherProfileRepository({TeacherProfile? profile})
    : _byId = profile == null ? {} : {profile.id: profile},
      _byUserId = profile == null ? {} : {profile.userId: profile};

  final Map<String, TeacherProfile> _byId;
  final Map<String, TeacherProfile> _byUserId;
  int getProfileByIdCallCount = 0;
  int getProfileByUserIdCallCount = 0;

  /// Last profile passed to [updatePublicProfile] (for regression tests).
  TeacherProfile? lastUpdatedPublicProfile;

  void seed(TeacherProfile profile) {
    _byId[profile.id] = profile;
    _byUserId[profile.userId] = profile;
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> createProfile(
    TeacherProfile profile,
  ) async {
    seed(profile);
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
    getProfileByIdCallCount++;
    final profile = _byId[id];
    if (profile == null) {
      return const Left(NotFoundFailure('TeacherProfile'));
    }
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileByUserId(
    String userId,
  ) async {
    getProfileByUserIdCallCount++;
    final profile = _byUserId[userId];
    if (profile == null) {
      return const Left(NotFoundFailure('TeacherProfile'));
    }
    return Right(profile);
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
    seed(profile);
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> updatePublicProfile(
    TeacherProfile profile,
  ) async {
    lastUpdatedPublicProfile = profile;
    seed(profile);
    return Right(profile);
  }
}
