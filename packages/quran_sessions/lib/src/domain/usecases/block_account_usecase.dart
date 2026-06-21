import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/user_profile_repository.dart';

class BlockAccountUseCase {
  const BlockAccountUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<Either<QuranSessionsFailure, void>> call({
    required String userId,
    required AccountRestrictionReason reason,
  }) => _repository.blockAccount(userId: userId, reason: reason);
}
