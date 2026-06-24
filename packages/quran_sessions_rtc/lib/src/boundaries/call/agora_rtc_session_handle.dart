import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Active Agora session resources released on leave/end.
abstract class AgoraRtcSessionHandle {
  Future<void> leaveAndRelease();

  Future<void> setMicrophoneMuted(bool muted);

  /// Native engine for in-call video rendering; null in test fakes.
  RtcEngine? get engine;
}

/// Production handle wrapping a native [RtcEngine].
class LiveAgoraRtcSessionHandle implements AgoraRtcSessionHandle {
  LiveAgoraRtcSessionHandle(this._engine);

  final RtcEngine _engine;

  @override
  Future<void> leaveAndRelease() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    await _engine.muteLocalAudioStream(muted);
  }

  @override
  RtcEngine get engine => _engine;
}
