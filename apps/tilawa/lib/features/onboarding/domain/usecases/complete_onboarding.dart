import '../repositories/onboarding_repository.dart';

class CompleteOnboarding {
  CompleteOnboarding(this._repository);
  final OnboardingRepository _repository;

  Future<void> call() => _repository.completeOnboarding();
}
