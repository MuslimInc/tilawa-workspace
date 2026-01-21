import 'package:injectable/injectable.dart';

import '../repositories/onboarding_repository.dart';

@injectable
class CompleteOnboarding {
  CompleteOnboarding(this._repository);
  final OnboardingRepository _repository;

  Future<void> call() => _repository.completeOnboarding();
}
