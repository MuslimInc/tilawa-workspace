import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/user_profile_repository.dart';

class GetUserProfileUseCase {
  const GetUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<Either<QuranSessionsFailure, UserProfile>> call(String userId) =>
      _repository.getProfile(userId);
}
