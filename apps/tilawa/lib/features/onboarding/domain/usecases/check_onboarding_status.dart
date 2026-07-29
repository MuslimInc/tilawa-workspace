import '../repositories/onboarding_repository.dart';

class CheckOnboardingStatus {
  CheckOnboardingStatus(this._repository);
  final OnboardingRepository _repository;

  Future<bool> call() => _repository.isOnboardingCompleted();
}
