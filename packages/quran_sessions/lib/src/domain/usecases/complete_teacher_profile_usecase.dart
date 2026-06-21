import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/session_policy_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../../utils/dob_validator.dart';

class CompleteTeacherProfileUseCase {
  const CompleteTeacherProfileUseCase(this._repository, this._policyRepository);

  final UserProfileRepository _repository;
  final SessionPolicyRepository _policyRepository;

  /// Saves the teacher's gender and date of birth.
  ///
  /// The date of birth is validated against the configured minimum teacher age
  /// ([QuranSessionSafetyPolicy.minimumTeacherAgeYears]).
  Future<Either<QuranSessionsFailure, UserProfile>> call({
    required String userId,
    required UserGender gender,
    required DateTime dateOfBirth,
  }) async {
    final policyResult = await _policyRepository.getGlobalPolicy();
    if (policyResult.isLeft) {
      return policyResult.fold(Left.new, (_) => throw StateError(''));
    }
    final policy = policyResult.fold((_) => throw StateError(''), (p) => p);

    final dobFailure = DobValidator.validate(
      dateOfBirth,
      minimumAgeYears: policy.minimumTeacherAgeYears,
    );
    if (dobFailure != null) return Left(dobFailure);

    final profileResult = await _repository.getProfile(userId);
    if (profileResult.isLeft) return profileResult.map((p) => p);
    final profile = profileResult.fold((_) => throw StateError(''), (p) => p);
    final updated = profile.copyWith(gender: gender, dateOfBirth: dateOfBirth);
    return _repository.updateProfile(updated);
  }
}
