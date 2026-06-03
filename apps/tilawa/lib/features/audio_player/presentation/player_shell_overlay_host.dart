/// In-shell expand/collapse driver for the footer [QuranPlayerWidget].
///
/// When bound, [PlayerPresentationController.expand] / [collapse] animate the
/// shell overlay instead of pushing `/player` (YouTube Music style).
abstract interface class PlayerShellOverlayHost {
  Future<void> expand();

  Future<void> collapse();
}
