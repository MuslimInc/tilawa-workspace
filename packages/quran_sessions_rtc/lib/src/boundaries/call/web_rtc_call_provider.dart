import 'package:quran_sessions/quran_sessions.dart';

/// WebRTC provider — signaling/TURN not wired for MVP.
///
/// Fails with [WebRtcSignalingUnavailableFailure] until a signaling server and
/// TURN credential CF ship. See specs/037 provider evaluation WebRTC section.
class WebRtcCallProvider implements SessionCallProvider, CallProvider {
  const WebRtcCallProvider({
    required this.tokenProvider,
    required this.signalingServerUrl,
  });

  final CallTokenProvider tokenProvider;
  final String signalingServerUrl;

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    if (request.providerKind != SessionCallProviderKind.webrtc) {
      throw const CallProviderUnavailableFailure();
    }
    if (signalingServerUrl.trim().isEmpty) {
      throw const WebRtcSignalingUnavailableFailure();
    }
    throw const WebRtcSignalingUnavailableFailure();
  }

  @override
  Future<CallRoom> joinSession(String sessionId) {
    throw const WebRtcSignalingUnavailableFailure();
  }

  @override
  Future<void> leaveSession(String sessionId) async {}

  @override
  Future<void> endSession(String sessionId) async {}

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {}

  @override
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  }) async {}

  @override
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  }) async {}

  @override
  Future<void> switchCamera(String sessionId) async {}

  @override
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  }) async {}
}
