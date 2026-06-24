import '../../domain/entities/call_join_request.dart';
import '../../domain/entities/session_call_provider_kind.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import 'call_provider.dart';
import 'call_room.dart';
import 'session_call_provider.dart';

/// Routes join to the correct provider using server-issued [CallJoinRequest].
class RoutingSessionCallProvider implements SessionCallProvider {
  RoutingSessionCallProvider({
    required this.external,
    required this.mock,
    this.agora,
    this.webrtc,
  });

  final SessionCallProvider external;
  final SessionCallProvider mock;
  final SessionCallProvider? agora;
  final SessionCallProvider? webrtc;

  final Map<String, SessionCallProviderKind> _activeProviders =
      <String, SessionCallProviderKind>{};

  SessionCallProvider _providerFor(SessionCallProviderKind kind) {
    return switch (kind) {
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
  }

  SessionCallProvider? _activeProviderFor(String sessionId) {
    final kind = _activeProviders[sessionId];
    if (kind == null) {
      return null;
    }
    return _providerFor(kind);
  }

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    final provider = _providerFor(request.providerKind);
    final room = await provider.join(request);
    _activeProviders[request.sessionId] = request.providerKind;
    return room;
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    final provider = _activeProviderFor(sessionId);
    if (provider == null) {
      return;
    }
    await provider.leaveSession(sessionId);
    _activeProviders.remove(sessionId);
  }

  @override
  Future<void> endSession(String sessionId) async {
    final provider = _activeProviderFor(sessionId);
    if (provider == null) {
      return;
    }
    await provider.endSession(sessionId);
    _activeProviders.remove(sessionId);
  }

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {
    final provider = _activeProviderFor(sessionId);
    if (provider == null) {
      return;
    }
    await provider.setMicrophoneMuted(sessionId, muted: muted);
  }

  @override
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    final provider = _activeProviderFor(sessionId);
    if (provider == null) {
      return;
    }
    await provider.setMicrophoneEnabled(sessionId, enabled: enabled);
  }

  @override
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    final provider = _activeProviderFor(sessionId);
    if (provider == null) {
      return;
    }
    await provider.setCameraEnabled(sessionId, enabled: enabled);
  }

  @override
  Future<void> switchCamera(String sessionId) async {
    final provider = _activeProviderFor(sessionId);
    if (provider == null) {
      return;
    }
    await provider.switchCamera(sessionId);
  }

  @override
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    final provider = _activeProviderFor(sessionId);
    if (provider == null) {
      return;
    }
    await provider.setSpeakerEnabled(sessionId, enabled: enabled);
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
