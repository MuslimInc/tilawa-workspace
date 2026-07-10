import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Active Agora session resources released on leave/end.
abstract class AgoraRtcSessionHandle {
  Future<void> leaveAndRelease({bool retainEngine = false});

  Future<void> setMicrophoneMuted(bool muted);

  Future<void> setCameraEnabled(bool enabled);

  Future<void> switchCamera();

  Future<void> setSpeakerEnabled(bool enabled);

  /// Native engine for in-call video rendering; null in test fakes.
  RtcEngine? get engine;
}

/// Production handle wrapping a native [RtcEngine].
class LiveAgoraRtcSessionHandle implements AgoraRtcSessionHandle {
  LiveAgoraRtcSessionHandle(this._engine, {required this.appId});

  final RtcEngine _engine;
  final String appId;

  @override
  Future<void> leaveAndRelease({bool retainEngine = false}) async {
    await _engine.leaveChannel();
    if (!retainEngine) {
      await _engine.release();
    }
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    await _engine.muteLocalAudioStream(muted);
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    // muteLocalVideoStream alone stops remote publish but keeps local preview
    // active; enableLocalVideo keeps capture/preview aligned with UI toggle.
    await _engine.enableLocalVideo(enabled);
    await _engine.muteLocalVideoStream(!enabled);
  }

  @override
  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }

  @override
  Future<void> setSpeakerEnabled(bool enabled) async {
    await _engine.setEnableSpeakerphone(enabled);
  }

  @override
  RtcEngine get engine => _engine;
}
