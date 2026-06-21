import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/user_profile_repository.dart';

class CompleteStudentProfileUseCase {
  const CompleteStudentProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  /// Saves the student's required profile fields.
  ///
  /// [countryCode] and [cityId] drive market resolution (pricing, currency,
  /// timezone) and are required for booking.
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
  }) async {
    final profileResult = await _repository.getProfile(userId);
    if (profileResult.isLeft) return profileResult.map((p) => p);
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
    );
    return _repository.updateProfile(updated);
  }
}
