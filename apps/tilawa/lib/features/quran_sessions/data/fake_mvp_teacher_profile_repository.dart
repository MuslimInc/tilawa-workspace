import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

/// In-memory fake for [TeacherProfileRepository].
///
/// Profiles are keyed by their [TeacherProfile.id] in the store.
/// A secondary index by [TeacherProfile.userId] is maintained for lookups.
class FakeMvpTeacherProfileRepository implements TeacherProfileRepository {
  FakeMvpTeacherProfileRepository(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileByUserId(
    String userId,
  ) async {
    final profile = _store.teacherProfiles.values
        .cast<TeacherProfile?>()
        .firstWhere((p) => p?.userId == userId, orElse: () => null);
    if (profile == null) return const Left(TeacherProfileNotApprovedFailure());
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileById(
    String id,
  ) async {
    final profile = _store.teacherProfiles[id];
    if (profile == null) return const Left(TeacherProfileNotApprovedFailure());
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> createProfile(
    TeacherProfile profile,
  ) async {
    _store.teacherProfiles[profile.id] = profile;
    return Right(profile);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> updateProfile(
    TeacherProfile profile,
  ) async {
    if (!_store.teacherProfiles.containsKey(profile.id)) {
      return const Left(TeacherProfileNotApprovedFailure());
    }
    final updated = profile.copyWith(updatedAt: DateTime.now());
    _store.teacherProfiles[profile.id] = updated;
    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> deactivate(
    String id,
  ) async {
    final profile = _store.teacherProfiles[id];
    if (profile == null) return const Left(TeacherProfileNotApprovedFailure());
    final deactivated = profile.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    _store.teacherProfiles[id] = deactivated;
    return Right(deactivated);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> reactivate(
    String id,
  ) async {
    final profile = _store.teacherProfiles[id];
    if (profile == null) return const Left(TeacherProfileNotApprovedFailure());
    final reactivated = profile.copyWith(
      isActive: true,
      updatedAt: DateTime.now(),
    );
    _store.teacherProfiles[id] = reactivated;
    return Right(reactivated);
  }
}
