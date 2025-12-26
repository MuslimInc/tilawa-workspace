import 'package:injectable/injectable.dart';

import '../repositories/onboarding_repository.dart';

@injectable
class CheckOnboardingStatus {
  CheckOnboardingStatus(this._repository);
  final OnboardingRepository _repository;

  Future<bool> call() => _repository.isOnboardingCompleted();
}
