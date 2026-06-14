/// Domain decision for how an available update should be handled.
enum InAppUpdateAction {
  performImmediate,
  startFlexible,
  promptFlexibleRestart,
  offerOptionalImmediate,
  offerRequiredStoreUpdate,
  none,
}

/// Presentation helpers for [InAppUpdateAction].
extension InAppUpdateActionPresentation on InAppUpdateAction {
  /// Whether the app should show a snackbar and wait for user confirmation.
  bool get requiresUserPrompt =>
      this == InAppUpdateAction.promptFlexibleRestart ||
      this == InAppUpdateAction.offerOptionalImmediate ||
      this == InAppUpdateAction.offerRequiredStoreUpdate;

  /// Optional prompts can be throttled; required prompts cannot.
  bool get isOptionalUserPrompt =>
      this == InAppUpdateAction.offerOptionalImmediate;
}
