abstract interface class OnboardingRepository {
  /// Checks if the user has completed the onboarding flow.
  Future<bool> isOnboardingCompleted();

  /// Marks the onboarding flow as completed.
  Future<void> completeOnboarding();
}
