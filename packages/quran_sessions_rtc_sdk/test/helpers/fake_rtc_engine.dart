import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';
import 'package:quran_sessions_rtc_sdk/quran_sessions_rtc_sdk.dart';

/// Minimal [RtcEngine] fake for widget and boundary tests.
class FakeRtcEngine implements RtcEngine {
  RtcEngineEventHandler? handler;
  bool leftChannel = false;
  bool released = false;
  bool? microphoneMuted;
  bool? videoMuted;
  bool? speakerEnabled;
  bool switchedCamera = false;

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

  @override
  Future<void> muteLocalVideoStream(bool mute) async {
    videoMuted = mute;
  }

  @override
  Future<void> switchCamera() async {
    switchedCamera = true;
  }

  @override
  Future<void> setEnableSpeakerphone(bool enabled) async {
    speakerEnabled = enabled;
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

  void simulateConnectionStateChanged({
    required ConnectionStateType state,
    ConnectionChangedReasonType reason =
        ConnectionChangedReasonType.connectionChangedConnecting,
    String channelId = 'channel-1',
  }) {
    handler?.onConnectionStateChanged?.call(
      RtcConnection(channelId: channelId),
      state,
      reason,
    );
  }

  void simulateNetworkQuality({
    required QualityType txQuality,
    required QualityType rxQuality,
    int uid = 0,
    String channelId = 'channel-1',
  }) {
    handler?.onNetworkQuality?.call(
      RtcConnection(channelId: channelId),
      uid,
      txQuality,
      rxQuality,
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
  Future<void> leaveAndRelease({bool retainEngine = false}) async {
    released = !retainEngine;
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
}

const testAgoraCallSurfaceLabels = AgoraCallSurfaceLabels(
  connecting: 'Connecting',
  connected: 'Connected',
  waitingForParticipant: 'Waiting for participant',
  voiceCallTitle: 'Voice call',
);
