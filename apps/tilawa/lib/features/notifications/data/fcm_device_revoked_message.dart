/// Normalizes FCM data payloads for `device_revoked` pushes (ADR-008 Phase 3,
/// Manage Devices). Device-targeted control message sent when this device is
/// signed out remotely ("Sign out this device" / "Sign out all other
/// devices"). Unlike `session_taken_over`, it ends the whole-app session on the
/// receiving device.
bool isDeviceRevokedFcmMessage(Map<String, dynamic> data) {
  final dynamic rawType = data['type'] ?? data['actionType'];
  final String? type = rawType?.toString().trim().toLowerCase();
  return type == 'device_revoked';
}
