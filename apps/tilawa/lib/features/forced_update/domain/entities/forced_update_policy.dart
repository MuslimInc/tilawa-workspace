/// Remote min-build policy for forced store updates.
///
/// Missing platform fields fail open (no gate). Set
/// `android_min_build_number` / `ios_min_build_number` in Firestore
/// `app_config/in_app_update`.
class ForcedUpdatePolicy {
  const ForcedUpdatePolicy({
    this.androidMinBuildNumber,
    this.iosMinBuildNumber,
  });

  final int? androidMinBuildNumber;
  final int? iosMinBuildNumber;
}
