import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

/// MVP implementation of [SessionPolicyRepository] backed by [QuranSessionsMvpStore].
class FakeMvpSessionPolicyRepository implements SessionPolicyRepository {
  FakeMvpSessionPolicyRepository(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, QuranSessionSafetyPolicy>>
  getGlobalPolicy() async {
    return Right(_store.globalSafetyPolicy);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherEligibilityPolicy>>
  getTeacherEligibilityPolicy(String teacherId) async {
    final policy =
        _store.teacherEligibilityPolicies[teacherId] ??
        TeacherEligibilityPolicy.unrestricted;
    return Right(policy);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> updateGlobalPolicy(
    QuranSessionSafetyPolicy policy,
  ) async {
    _store.globalSafetyPolicy = policy;
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> updateTeacherEligibilityPolicy({
    required String teacherId,
    required TeacherEligibilityPolicy policy,
  }) async {
    _store.teacherEligibilityPolicies[teacherId] = policy;
    return const Right(null);
  }
}
