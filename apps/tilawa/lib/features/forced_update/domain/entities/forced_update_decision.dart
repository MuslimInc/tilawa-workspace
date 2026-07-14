/// Whether the installed build must update before continuing.
enum ForcedUpdateDecision {
  /// Installed build is below the remote platform minimum.
  required,

  /// No gate — current, non-mobile, or fail-open.
  none,
}
