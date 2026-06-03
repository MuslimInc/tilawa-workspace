/// Tracks whether the dedicated prayer-alerts permission flow was shown.
abstract class PrayerAlertsPermissionOnboardingRepository {
  /// `true` after the user completes or skips the full flow once.
  Future<bool> wasFlowCompleted();

  Future<void> markFlowCompleted();
}
