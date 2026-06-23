import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

/// MVP implementation of [UserProfileRepository] backed by [QuranSessionsMvpStore].
///
/// The student profile starts **incomplete** (no gender / DOB) to exercise the
/// profile-completion gate on first booking attempt.
class FakeMvpUserProfileRepository implements UserProfileRepository {
  FakeMvpUserProfileRepository(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> getProfile(
    String userId,
  ) async {
    final profile = _store.profiles[userId];
    if (profile == null) return Left(NotFoundFailure('UserProfile($userId)'));
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> updateProfile(
    UserProfile profile,
  ) async {
    _store.profiles[profile.userId] = profile;
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> blockAccount({
    required String userId,
    required AccountRestrictionReason reason,
  }) async {
    final profile = _store.profiles[userId];
    if (profile == null) return Left(NotFoundFailure('UserProfile($userId)'));
    _store.profiles[userId] = profile.copyWith(
      accountStatus: AccountStatus.blocked,
      restrictionReason: reason,
    );
    return const Right(null);
  }
}
