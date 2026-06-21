import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/user_profile_repository.dart';

class CompleteTeacherProfileUseCase {
  const CompleteTeacherProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  /// Saves the teacher's gender and date of birth.
  Future<Either<QuranSessionsFailure, UserProfile>> call({
    required String userId,
    required UserGender gender,
    required DateTime dateOfBirth,
  }) async {
    final profileResult = await _repository.getProfile(userId);
    if (profileResult.isLeft) return profileResult.map((p) => p);
    final profile = profileResult.fold((_) => throw StateError(''), (p) => p);
    final updated = profile.copyWith(gender: gender, dateOfBirth: dateOfBirth);
    return _repository.updateProfile(updated);
  }
}
