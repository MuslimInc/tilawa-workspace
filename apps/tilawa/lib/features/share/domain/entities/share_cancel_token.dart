/// Cooperative cancellation for long-running share generation.
class ShareCancelToken {
  final List<void Function()> _onCancelListeners = <void Function()>[];
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  /// Registers a listener invoked when [cancel] is called.
  void addCancelListener(void Function() listener) {
    if (_isCancelled) {
      listener();
      return;
    }
    _onCancelListeners.add(listener);
  }

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    for (final void Function() listener in List<void Function()>.from(
      _onCancelListeners,
    )) {
      listener();
    }
  }
}
