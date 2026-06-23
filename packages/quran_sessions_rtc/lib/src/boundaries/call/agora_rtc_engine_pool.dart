import 'agora_rtc_session_handle.dart';

/// Keeps one [AgoraRtcSessionHandle] per active session for leave/end lifecycle.
class AgoraRtcEnginePool {
  AgoraRtcEnginePool();

  final Map<String, AgoraRtcSessionHandle> _sessions =
      <String, AgoraRtcSessionHandle>{};

  AgoraRtcSessionHandle? sessionFor(String sessionId) => _sessions[sessionId];

  void remember(String sessionId, AgoraRtcSessionHandle handle) {
    _sessions[sessionId] = handle;
  }

  Future<AgoraRtcSessionHandle?> release(String sessionId) async {
    final handle = _sessions.remove(sessionId);
    if (handle == null) {
      return null;
    }
    await handle.leaveAndRelease();
    return handle;
  }

  Future<void> releaseAll() async {
    final ids = _sessions.keys.toList(growable: false);
    for (final sessionId in ids) {
      await release(sessionId);
    }
  }
}
