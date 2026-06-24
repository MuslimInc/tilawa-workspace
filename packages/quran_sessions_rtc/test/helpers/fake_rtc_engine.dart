import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

/// Minimal [RtcEngine] fake for widget and boundary tests.
class FakeRtcEngine implements RtcEngine {
  RtcEngineEventHandler? handler;
  bool leftChannel = false;
  bool released = false;
  bool? microphoneMuted;

  @override
  void registerEventHandler(RtcEngineEventHandler eventHandler) {
    handler = eventHandler;
  }

  @override
  void unregisterEventHandler(RtcEngineEventHandler eventHandler) {
    if (handler == eventHandler) {
      handler = null;
    }
  }

  @override
  Future<void> leaveChannel({LeaveChannelOptions? options}) async {
    leftChannel = true;
  }

  @override
  Future<void> release({bool sync = false}) async {
    released = true;
  }

  @override
  Future<void> muteLocalAudioStream(bool mute) async {
    microphoneMuted = mute;
  }

  void simulateJoinSuccess({String channelId = 'channel-1'}) {
    handler?.onJoinChannelSuccess?.call(RtcConnection(channelId: channelId), 0);
  }

  void simulateUserJoined({
    required int remoteUid,
    String channelId = 'channel-1',
  }) {
    handler?.onUserJoined?.call(
      RtcConnection(channelId: channelId),
      remoteUid,
      0,
    );
  }

  void simulateUserOffline({
    required int remoteUid,
    String channelId = 'channel-1',
  }) {
    handler?.onUserOffline?.call(
      RtcConnection(channelId: channelId),
      remoteUid,
      UserOfflineReasonType.userOfflineQuit,
    );
  }

  void simulateRemoteVideoState({
    required int remoteUid,
    required RemoteVideoState state,
    String channelId = 'channel-1',
  }) {
    handler?.onRemoteVideoStateChanged?.call(
      RtcConnection(channelId: channelId),
      remoteUid,
      state,
      RemoteVideoStateReason.remoteVideoStateReasonLocalMuted,
      0,
    );
  }

  void simulateLocalVideoState(LocalVideoStreamState state) {
    handler?.onLocalVideoStateChanged?.call(
      VideoSourceType.videoSourceCameraPrimary,
      state,
      LocalVideoStreamReason.localVideoStreamReasonOk,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// [AgoraRtcSessionHandle] backed by [FakeRtcEngine].
class FakeAgoraRtcSessionHandle implements AgoraRtcSessionHandle {
  FakeAgoraRtcSessionHandle(this._engine);

  final FakeRtcEngine _engine;
  bool released = false;

  @override
  RtcEngine get engine => _engine;

  @override
  Future<void> leaveAndRelease() async {
    released = true;
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    await _engine.muteLocalAudioStream(muted);
  }
}

const testAgoraCallSurfaceLabels = AgoraCallSurfaceLabels(
  connecting: 'Connecting',
  connected: 'Connected',
  waitingForParticipant: 'Waiting for participant',
  voiceCallTitle: 'Voice call',
);
