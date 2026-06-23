import 'dart:async';

import 'package:injectable/injectable.dart';

/// Broadcasts `session_revoked` FCM events (one shot per push).
///
/// [SessionValidityCubit] subscribes at app root so stale devices sign out
/// without a Firestore listener.
@lazySingleton
class SessionRevokedNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  bool _notified = false;

  Stream<void> get onSessionRevoked => _controller.stream;

  /// Notifies listeners once (dedupes FCM retries).
  void notifySessionRevoked() {
    if (_notified) {
      return;
    }
    _notified = true;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void resetDedupeForTest() {
    _notified = false;
  }
}
