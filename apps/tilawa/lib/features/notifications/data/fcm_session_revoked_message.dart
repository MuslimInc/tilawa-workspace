/// Normalizes FCM data payloads for `session_revoked` pushes.
bool isSessionRevokedFcmMessage(Map<String, dynamic> data) {
  final dynamic rawType = data['type'] ?? data['actionType'];
  final String? type = rawType?.toString().trim().toLowerCase();
  return type == 'session_revoked';
}
