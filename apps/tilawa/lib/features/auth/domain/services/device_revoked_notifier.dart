import 'dart:async';

import 'package:injectable/injectable.dart';

/// Broadcasts `device_revoked` FCM events (ADR-008 Phase 3, Manage Devices).
///
/// Emitted when *this* device is signed out remotely. Unlike
/// `session_taken_over` (live-session scoped, no logout), a device revocation
/// ends the whole-app session on this device regardless of the multi-device
/// login flag — it is a user-intended, definitive sign-out. A listener at the
/// app root performs the local sign-out and routes to login.
@lazySingleton
class DeviceRevokedNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get onDeviceRevoked => _controller.stream;

  void notifyDeviceRevoked() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
