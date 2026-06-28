import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/user_profile_repository.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({UserProfile? profile})
    : _profile =
          profile ??
          const UserProfile(
            userId: 'student_1',
            role: UserRole.student,
            accountStatus: AccountStatus.active,
            gender: UserGender.male,
          );

  UserProfile _profile;
  QuranSessionsFailure? failWith;
  int getProfileCallCount = 0;

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> getProfile(
    String userId,
  ) async {
    getProfileCallCount++;
    if (failWith != null) return Left(failWith!);
    return Right(_profile);
  }

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> updateProfile(
    UserProfile profile,
  ) async {
    if (failWith != null) return Left(failWith!);
    _profile = profile;
    return Right(_profile);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> blockAccount({
    required String userId,
    required AccountRestrictionReason reason,
  }) async {
    if (failWith != null) return Left(failWith!);
    _profile = _profile.copyWith(
      accountStatus: AccountStatus.blocked,
      restrictionReason: reason,
    );
    return const Right(null);
  }
}
