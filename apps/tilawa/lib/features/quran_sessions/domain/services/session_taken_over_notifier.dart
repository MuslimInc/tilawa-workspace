import 'dart:async';

import 'package:injectable/injectable.dart';

/// Broadcasts `session_taken_over` FCM events, scoped to a live session
/// (ADR-008 Phase 2).
///
/// Distinct from [SessionRevokedNotifier]: a takeover never signs the user out
/// of the app — it only means the same user joined the *same live session* from
/// another device. The receiver leaves the RTC room and surfaces a
/// "Moved to another device" message. Emits the affected `sessionId`.
@lazySingleton
class SessionTakenOverNotifier {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get onSessionTakenOver => _controller.stream;

  /// Notifies listeners that `sessionId` was taken over on another device.
  void notifySessionTakenOver(String sessionId) {
    if (!_controller.isClosed) {
      _controller.add(sessionId);
    }
  }
}
