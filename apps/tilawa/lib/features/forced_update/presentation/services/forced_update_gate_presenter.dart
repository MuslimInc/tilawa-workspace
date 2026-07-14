/// Shows / dismisses the blocking forced-update gate.
abstract class ForcedUpdateGatePresenter {
  /// Presents the non-dismissible gate if not already visible.
  void showGate({required Future<void> Function() onUpdate});

  /// Dismisses the gate when the install is no longer behind policy.
  void dismissGate();

  /// Whether the gate route is currently on screen.
  bool get isShowing;
}
