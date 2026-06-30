import 'livekit_rtc_session_handle.dart';

/// Tracks active LiveKit sessions keyed by Quran session id.
class LiveKitRoomPool {
  final Map<String, LiveKitRtcSessionHandle> _sessions =
      <String, LiveKitRtcSessionHandle>{};

  LiveKitRtcSessionHandle? sessionFor(String sessionId) => _sessions[sessionId];

  void remember(String sessionId, LiveKitRtcSessionHandle handle) {
    _sessions[sessionId] = handle;
  }

  Future<void> release(String sessionId) async {
    final handle = _sessions.remove(sessionId);
    if (handle == null) {
      return;
    }
    await handle.leaveAndRelease();
  }
}
