/// UI rollout toggles for Quran Sessions presentation layer.
///
/// Backend/domain report and dispute flows stay wired; only user-facing entry
/// points respect these flags until the feature ships.
abstract final class QuranSessionsLaunchScope {
  /// Report concern, open dispute, and report tutor actions.
  static const reportDisputeUiEnabled = false;
}
