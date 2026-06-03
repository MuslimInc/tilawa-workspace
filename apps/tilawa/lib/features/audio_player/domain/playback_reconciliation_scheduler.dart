import 'dart:async';

/// Coalesces handler→bloc reconciliation: leading sync per burst, optional
/// trailing sync when requests continue within [debounce].
///
/// Replaces microtask + 200ms + startup timers with one pipeline (≤2 fires per
/// burst).
final class PlaybackReconciliationScheduler {
  PlaybackReconciliationScheduler({
    required this.onFire,
    this.debounce = const Duration(milliseconds: 150),
  });

  final void Function({required bool trailing}) onFire;

  final Duration debounce;

  Timer? _timer;
  bool _disposed = false;
  bool _inBurst = false;
  bool _trailingNeeded = false;

  /// Schedules reconciliation.
  ///
  /// First [request] in a quiet period fires [onFire] immediately. Further
  /// [request] calls within [debounce] schedule at most one trailing [onFire].
  void request() {
    if (_disposed) {
      return;
    }

    if (!_inBurst) {
      _inBurst = true;
      onFire(trailing: false);
    } else {
      _trailingNeeded = true;
    }

    _timer?.cancel();
    _timer = Timer(debounce, () {
      if (_disposed) {
        return;
      }
      if (_trailingNeeded) {
        onFire(trailing: true);
      }
      _inBurst = false;
      _trailingNeeded = false;
      _timer = null;
    });
  }

  /// Cancels a pending trailing fire without calling [onFire].
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _inBurst = false;
    _trailingNeeded = false;
  }

  void dispose() {
    _disposed = true;
    cancel();
  }
}
