import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_policy.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/session_policy_repository.dart';

class UpdateTeacherEligibilityPolicyUseCase {
  const UpdateTeacherEligibilityPolicyUseCase(this._repository);

  final SessionPolicyRepository _repository;

  Future<Either<QuranSessionsFailure, void>> call({
    required String teacherId,
    required TeacherEligibilityPolicy policy,
  }) => _repository.updateTeacherEligibilityPolicy(
    teacherId: teacherId,
    policy: policy,
  );
}
