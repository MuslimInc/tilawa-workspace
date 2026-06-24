/// Accumulates *both-connected* call duration as connectivity intervals open
/// and close. Pure and clamped: a negative interval can never be produced, so
/// out-of-order or corrupt timestamps degrade to zero rather than a wrong
/// (negative) total.
class CallDurationCalculator {
  int _accumulatedSeconds = 0;
  int? _openSinceMs;

  /// Total whole seconds during which both participants were connected.
  int get totalSeconds => _accumulatedSeconds;

  /// Whether a both-connected interval is currently open.
  bool get isOpen => _openSinceMs != null;

  /// Opens an interval at [nowMs] if one is not already open.
  void open(int nowMs) {
    _openSinceMs ??= nowMs;
  }

  /// Closes the open interval (if any) at [nowMs], adding the clamped delta.
  void close(int nowMs) {
    final since = _openSinceMs;
    if (since == null) {
      return;
    }
    final deltaSeconds = (nowMs - since) ~/ 1000;
    if (deltaSeconds > 0) {
      _accumulatedSeconds += deltaSeconds;
    }
    _openSinceMs = null;
  }
}
