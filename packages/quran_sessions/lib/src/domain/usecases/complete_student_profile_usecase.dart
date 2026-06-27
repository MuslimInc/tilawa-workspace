import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/session_policy_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../../utils/dob_validator.dart';

class CompleteStudentProfileUseCase {
  const CompleteStudentProfileUseCase(this._repository, this._policyRepository);

  final UserProfileRepository _repository;
  final SessionPolicyRepository _policyRepository;

  /// Saves the student's required profile fields.
  ///
  /// [countryCode] and [cityId] drive market resolution (pricing, currency,
  /// timezone) and are required for booking.
  ///
  /// The date of birth is validated against the configured minimum student age
  /// ([QuranSessionSafetyPolicy.minimumStudentAgeYears]) — the authoritative
  /// final gate, enforced even if the UI picker is bypassed.
  Future<Either<QuranSessionsFailure, UserProfile>> call({
    required String userId,
    required UserGender gender,
    required DateTime dateOfBirth,
    required String countryCode,
    required String countryName,
    required String cityId,
    required String cityName,
    required String currencyCode,
    required String timezone,
    List<StudentLearningGoal> learningGoals = const [],
  }) async {
    final policyResult = await _policyRepository.getGlobalPolicy();
    if (policyResult.isLeft()) {
      return policyResult.fold(Left.new, (_) => throw StateError(''));
    }
    final policy = policyResult.fold((_) => throw StateError(''), (p) => p);

    final dobFailure = DobValidator.validate(
      dateOfBirth,
      minimumAgeYears: policy.minimumStudentAgeYears,
    );
    if (dobFailure != null) return Left(dobFailure);

    final profileResult = await _repository.getProfile(userId);
    if (profileResult.isLeft()) return profileResult.map((p) => p);
    final profile = profileResult.fold((_) => throw StateError(''), (p) => p);
    final updated = profile.copyWith(
      gender: gender,
      dateOfBirth: dateOfBirth,
      countryCode: countryCode,
      countryName: countryName,
      cityId: cityId,
      cityName: cityName,
      currencyCode: currencyCode,
      timezone: timezone,
      learningGoals: learningGoals,
    );
    return _repository.updateProfile(updated);
  }
}
