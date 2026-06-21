import 'package:dartz_plus/dartz_plus.dart';

import '../../../lib/src/domain/entities/session_policy.dart';
import '../../../lib/src/domain/failures/quran_sessions_failure.dart';
import '../../../lib/src/domain/repositories/session_policy_repository.dart';

class FakeSessionPolicyRepository implements SessionPolicyRepository {
  QuranSessionSafetyPolicy globalPolicy = const QuranSessionSafetyPolicy();
  final Map<String, TeacherEligibilityPolicy> teacherPolicies = {};
  QuranSessionsFailure? failWith;

  @override
  Future<Either<QuranSessionsFailure, QuranSessionSafetyPolicy>>
  getGlobalPolicy() async {
    if (failWith != null) return Left(failWith!);
    return Right(globalPolicy);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherEligibilityPolicy>>
  getTeacherEligibilityPolicy(String teacherId) async {
    if (failWith != null) return Left(failWith!);
    return Right(
      teacherPolicies[teacherId] ?? TeacherEligibilityPolicy.unrestricted,
    );
  }

  @override
  Future<Either<QuranSessionsFailure, void>> updateGlobalPolicy(
    QuranSessionSafetyPolicy policy,
  ) async {
    if (failWith != null) return Left(failWith!);
    globalPolicy = policy;
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> updateTeacherEligibilityPolicy({
    required String teacherId,
    required TeacherEligibilityPolicy policy,
  }) async {
    if (failWith != null) return Left(failWith!);
    teacherPolicies[teacherId] = policy;
    return const Right(null);
  }
}
