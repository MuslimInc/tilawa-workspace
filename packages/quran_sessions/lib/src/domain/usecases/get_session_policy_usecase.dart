import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_policy.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/session_policy_repository.dart';

class GetSessionPolicyUseCase {
  const GetSessionPolicyUseCase(this._repository);

  final SessionPolicyRepository _repository;

  Future<Either<QuranSessionsFailure, QuranSessionSafetyPolicy>> call() =>
      _repository.getGlobalPolicy();
}
