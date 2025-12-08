class ProgressThrottler {
  DateTime? _lastUpdateTime;
  int _lastReceived = 0;

  bool shouldSendUpdate({
    required int received,
    required int total,
    required double progress,
  }) {
    if (received == 0 || received == total) {
      return true;
    }

    if (total > 0) {
      final double change = (received - _lastReceived).abs() / total;
      if (change >= 0.01) {
        return true;
      }
    }

    if (_lastUpdateTime != null &&
        DateTime.now().difference(_lastUpdateTime!) >=
            const Duration(milliseconds: 100)) {
      return true;
    }

    // If never updated but received > 0 (handled by received==0 check roughly, but logic safety)
    if (_lastUpdateTime == null) {
      return true;
    }

    return false;
  }

  bool shouldSendUpdateUnknownSize({required int received}) {
    if (received == 0) {
      return true;
    }

    if (_lastUpdateTime != null &&
        DateTime.now().difference(_lastUpdateTime!) >=
            const Duration(milliseconds: 100)) {
      return true;
    }

    if (_lastUpdateTime == null) {
      return true;
    }

    return false;
  }

  void recordUpdate({required int received}) {
    _lastUpdateTime = DateTime.now();
    _lastReceived = received;
  }

  void reset() {
    _lastUpdateTime = null;
    _lastReceived = 0;
  }
}
