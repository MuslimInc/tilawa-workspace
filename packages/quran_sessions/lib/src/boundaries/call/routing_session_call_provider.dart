import '../../domain/entities/call_join_request.dart';
import '../../domain/entities/session_call_provider_kind.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import 'call_provider.dart';
import 'call_room.dart';
import 'session_call_provider.dart';

/// Routes join to the correct provider using server-issued [CallJoinRequest].
class RoutingSessionCallProvider implements SessionCallProvider {
  const RoutingSessionCallProvider({
    required this.external,
    required this.mock,
    this.agora,
    this.webrtc,
  });

  final SessionCallProvider external;
  final SessionCallProvider mock;
  final SessionCallProvider? agora;
  final SessionCallProvider? webrtc;

  @override
  Future<CallRoom> join(CallJoinRequest request) {
    final provider = switch (request.providerKind) {
      SessionCallProviderKind.external => external,
      SessionCallProviderKind.mock => mock,
      SessionCallProviderKind.agora =>
        agora ??
            (throw const CallProviderUnavailableFailure(
              reasonCode: 'agora_not_registered',
            )),
      SessionCallProviderKind.webrtc =>
        webrtc ??
            (throw const CallProviderUnavailableFailure(
              reasonCode: 'webrtc_not_registered',
            )),
    };
    return provider.join(request);
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    await external.leaveSession(sessionId);
    await mock.leaveSession(sessionId);
    await agora?.leaveSession(sessionId);
    await webrtc?.leaveSession(sessionId);
  }

  @override
  Future<void> endSession(String sessionId) async {
    await external.endSession(sessionId);
    await mock.endSession(sessionId);
    await agora?.endSession(sessionId);
    await webrtc?.endSession(sessionId);
  }

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {
    await external.setMicrophoneMuted(sessionId, muted: muted);
    await mock.setMicrophoneMuted(sessionId, muted: muted);
    await agora?.setMicrophoneMuted(sessionId, muted: muted);
    await webrtc?.setMicrophoneMuted(sessionId, muted: muted);
  }

  @override
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    await external.setMicrophoneEnabled(sessionId, enabled: enabled);
    await mock.setMicrophoneEnabled(sessionId, enabled: enabled);
    await agora?.setMicrophoneEnabled(sessionId, enabled: enabled);
    await webrtc?.setMicrophoneEnabled(sessionId, enabled: enabled);
  }

  @override
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    await external.setCameraEnabled(sessionId, enabled: enabled);
    await mock.setCameraEnabled(sessionId, enabled: enabled);
    await agora?.setCameraEnabled(sessionId, enabled: enabled);
    await webrtc?.setCameraEnabled(sessionId, enabled: enabled);
  }

  @override
  Future<void> switchCamera(String sessionId) async {
    await external.switchCamera(sessionId);
    await mock.switchCamera(sessionId);
    await agora?.switchCamera(sessionId);
    await webrtc?.switchCamera(sessionId);
  }

  @override
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    await external.setSpeakerEnabled(sessionId, enabled: enabled);
    await mock.setSpeakerEnabled(sessionId, enabled: enabled);
    await agora?.setSpeakerEnabled(sessionId, enabled: enabled);
    await webrtc?.setSpeakerEnabled(sessionId, enabled: enabled);
  }
}

/// Adapts [SessionCallProvider] to legacy [CallProvider] (student join).
class CallProviderAdapter implements CallProvider {
  const CallProviderAdapter(
    this._inner, {
    this.resolveRequest,
  });

  final SessionCallProvider _inner;

  /// When omitted, [joinSession] cannot run — use [JoinSessionUseCase] instead.
  final Future<CallJoinRequest> Function(String sessionId)? resolveRequest;

  @override
  Future<CallRoom> joinSession(String sessionId) async {
    final resolver = resolveRequest;
    if (resolver == null) {
      throw const CallProviderUnavailableFailure();
    }
    return _inner.join(await resolver(sessionId));
  }

  @override
  Future<void> leaveSession(String sessionId) => _inner.leaveSession(sessionId);

  @override
  Future<void> endSession(String sessionId) => _inner.endSession(sessionId);
}
