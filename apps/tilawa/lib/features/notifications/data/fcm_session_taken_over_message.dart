/// Normalizes FCM data payloads for `session_taken_over` pushes (ADR-008
/// Phase 2). Device-targeted control message sent to the previous lock holder
/// when the same user joins the live session from another device.
bool isSessionTakenOverFcmMessage(Map<String, dynamic> data) {
  final dynamic rawType = data['type'] ?? data['actionType'];
  final String? type = rawType?.toString().trim().toLowerCase();
  return type == 'session_taken_over';
}

/// Extracts the affected session id from a `session_taken_over` payload, or
/// `null` when absent.
String? sessionTakenOverSessionId(Map<String, dynamic> data) {
  final dynamic raw = data['sessionId'];
  if (raw == null) return null;
  final id = raw.toString().trim();
  return id.isEmpty ? null : id;
}
