import 'package:quran_sessions/quran_sessions.dart';

import 'agora_rtc_engine_pool.dart';
import 'agora_rtc_join_gateway.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

/// Agora voice/video join via server-issued channel + token.
class AgoraCallProvider implements SessionCallProvider, CallProvider {
  AgoraCallProvider({
    required this.appId,
    required this.tokenProvider,
    required this.resolveUserId,
    this.permissionGate = const RtcPermissionGate(),
    this.eventHub,
    AgoraRtcEnginePool? enginePool,
    AgoraRtcJoinGateway? joinGateway,
  }) : _enginePool = enginePool ?? AgoraRtcEnginePool(),
       _joinGateway = joinGateway ?? LiveAgoraRtcJoinGateway();

  final String appId;
  final CallTokenProvider tokenProvider;
  final Future<String> Function() resolveUserId;
  final RtcPermissionGate permissionGate;
  final SessionCallProviderEventHub? eventHub;
  final AgoraRtcEnginePool _enginePool;
  final AgoraRtcJoinGateway _joinGateway;
  final Map<String, Future<CallRoom>> _joinInFlight =
      <String, Future<CallRoom>>{};

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    if (request.providerKind != SessionCallProviderKind.agora) {
      throw const CallProviderUnavailableFailure();
    }
    if (appId.trim().isEmpty) {
      throw const CallProviderUnavailableFailure();
    }

    final sessionId = request.sessionId;
    final inFlight = _joinInFlight[sessionId];
    if (inFlight != null) {
      return inFlight;
    }

    final joinFuture = _joinOnce(request);
    _joinInFlight[sessionId] = joinFuture;
    try {
      return await joinFuture;
    } finally {
      _joinInFlight.remove(sessionId);
    }
  }

  Future<CallRoom> _joinOnce(CallJoinRequest request) async {
    await permissionGate.ensureGranted(
      needsCamera: request.callType == SessionCallType.videoCall,
    );

    // Drop any stale engine still bound to this session before re-joining.
    await _enginePool.release(request.sessionId);

    final userId = await resolveUserId();
    final credentials = await tokenProvider.fetchCredentials(
      sessionId: request.sessionId,
      userId: userId,
    );

    if (credentials.token.isEmpty) {
      throw const RtcCallJoinFailure(reasonCode: 'missing_join_token');
    }

    final effectiveAppId = credentials.appId.isNotEmpty
        ? credentials.appId
        : appId.trim();

    final handle = await _joinGateway.join(
      AgoraRtcJoinParams(
        appId: effectiveAppId,
        token: credentials.token,
        channelId: credentials.channelId,
        uid: credentials.uid,
        enableVideo: request.callType == SessionCallType.videoCall,
        existingEngine: _enginePool.takeParkedEngine(effectiveAppId),
      ),
    );

    _enginePool.remember(request.sessionId, handle);

    eventHub?.emit(SessionCallLocalChannelJoined(sessionId: request.sessionId));

    return CallRoom(
      sessionId: request.sessionId,
      channelId: credentials.channelId,
      token: credentials.token,
      extraData: {
        'providerKind': SessionCallProviderKind.agora.name,
        'callType': request.callType.name,
        'role': request.role.name,
        'agoraUid': credentials.uid,
      },
    );
  }

  @override
  Future<CallRoom> joinSession(String sessionId) {
    throw const CallProviderUnavailableFailure();
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    await _enginePool.release(sessionId);
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _enginePool.release(sessionId);
  }

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {
    final handle = _enginePool.sessionFor(sessionId);
    if (handle == null) {
      return;
    }
    await handle.setMicrophoneMuted(muted);
  }

  @override
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  }) => setMicrophoneMuted(sessionId, muted: !enabled);

  @override
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    final handle = _enginePool.sessionFor(sessionId);
    if (handle == null) {
      return;
    }
    await handle.setCameraEnabled(enabled);
  }

  @override
  Future<void> switchCamera(String sessionId) async {
    final handle = _enginePool.sessionFor(sessionId);
    if (handle == null) {
      return;
    }
    await handle.switchCamera();
  }

  @override
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    final handle = _enginePool.sessionFor(sessionId);
    if (handle == null) {
      return;
    }
    await handle.setSpeakerEnabled(enabled);
  }
}
