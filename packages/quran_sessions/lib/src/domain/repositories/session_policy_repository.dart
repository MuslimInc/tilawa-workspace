import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_policy.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class SessionPolicyRepository {
  Future<Either<QuranSessionsFailure, QuranSessionSafetyPolicy>>
  getGlobalPolicy();

  Future<Either<QuranSessionsFailure, TeacherEligibilityPolicy>>
  getTeacherEligibilityPolicy(
    String teacherId,
  );

  Future<Either<QuranSessionsFailure, void>> updateGlobalPolicy(
    QuranSessionSafetyPolicy policy,
  );

  Future<Either<QuranSessionsFailure, void>> updateTeacherEligibilityPolicy({
    required String teacherId,
    required TeacherEligibilityPolicy policy,
  });
}
