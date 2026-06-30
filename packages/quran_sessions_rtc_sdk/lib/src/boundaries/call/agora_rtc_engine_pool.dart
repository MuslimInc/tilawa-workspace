import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'agora_rtc_session_handle.dart';

/// Keeps one [AgoraRtcSessionHandle] per active session for leave/end lifecycle.
///
/// When [retainEngineOnRelease] is true (default), the native [RtcEngine] is
/// parked after leave so the next join can skip engine creation.
class AgoraRtcEnginePool {
  AgoraRtcEnginePool({this.retainEngineOnRelease = true});

  final bool retainEngineOnRelease;

  final Map<String, AgoraRtcSessionHandle> _sessions =
      <String, AgoraRtcSessionHandle>{};

  RtcEngine? _parkedEngine;
  String? _parkedEngineAppId;

  AgoraRtcSessionHandle? sessionFor(String sessionId) => _sessions[sessionId];

  /// Returns a parked engine when [appId] matches the last released session.
  RtcEngine? takeParkedEngine(String appId) {
    if (_parkedEngineAppId != appId) {
      return null;
    }
    final engine = _parkedEngine;
    _parkedEngine = null;
    _parkedEngineAppId = null;
    return engine;
  }

  void parkEngine(RtcEngine engine, String appId) {
    _parkedEngine = engine;
    _parkedEngineAppId = appId;
  }

  void remember(String sessionId, AgoraRtcSessionHandle handle) {
    _sessions[sessionId] = handle;
  }

  Future<AgoraRtcSessionHandle?> release(String sessionId) async {
    final handle = _sessions.remove(sessionId);
    if (handle == null) {
      return null;
    }
    final engine = handle.engine;
    if (retainEngineOnRelease && engine != null) {
      await handle.leaveAndRelease(retainEngine: true);
      final previous = _parkedEngine;
      if (previous != null && previous != engine) {
        await previous.release();
      }
      parkEngine(engine, _readEngineAppId(handle) ?? '');
    } else {
      await handle.leaveAndRelease();
    }
    return handle;
  }

  String? _readEngineAppId(AgoraRtcSessionHandle handle) {
    return handle is LiveAgoraRtcSessionHandle ? handle.appId : null;
  }

  Future<void> releaseAll() async {
    final ids = _sessions.keys.toList(growable: false);
    for (final sessionId in ids) {
      final handle = _sessions.remove(sessionId);
      if (handle != null) {
        await handle.leaveAndRelease();
      }
    }
    final parked = _parkedEngine;
    if (parked != null) {
      await parked.release();
    }
    _parkedEngine = null;
    _parkedEngineAppId = null;
  }
}
