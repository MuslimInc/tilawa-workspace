/// Explicit lifecycle phases for the Quran player presentation layer.
///
/// **Presentation state** only — not playback, navigation stack, or chrome.
/// See `docs/architecture/media-state-vocabulary.md`.
enum PlayerPresentationPhase {
  /// Footer mini visible; `/player` not on the navigation stack.
  mini,

  /// `/player` route push animation running (progress → 1).
  expanding,

  /// `/player` settled open (progress ≈ 1).
  expanded,

  /// `/player` route pop animation running (progress → 0).
  collapsing,
}
