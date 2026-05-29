/// Navigation contract for the expanded Quran player overlay route.
///
/// Implementation lives in the audio_player feature; register via DI.
abstract interface class QuranPlayerNavigation {
  /// Whether `/player` is currently on the root navigation stack.
  bool get isExpandedRouteOnStack;

  /// Pushes the typed overlay route. Completes when the route is popped.
  Future<void> pushExpanded();

  /// Pops the overlay route when present.
  void popExpanded();
}
