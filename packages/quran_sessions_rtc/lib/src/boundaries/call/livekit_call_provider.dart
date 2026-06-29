import 'package:quran_sessions/quran_sessions.dart';

import 'livekit_room_pool.dart';
import 'livekit_rtc_join_gateway.dart';
import 'rtc_permission_gate.dart';

/// LiveKit voice/video join via server-issued room token.
class LiveKitCallProvider implements SessionCallProvider, CallProvider {
  LiveKitCallProvider({
    required this.serverUrl,
    required this.tokenProvider,
    required this.resolveUserId,
    this.permissionGate = const RtcPermissionGate(),
    this.eventHub,
    LiveKitRoomPool? roomPool,
    LiveKitRtcJoinGateway? joinGateway,
  }) : _roomPool = roomPool ?? LiveKitRoomPool(),
       _joinGateway = joinGateway ?? LiveLiveKitRtcJoinGateway();

  final String serverUrl;
  final CallTokenProvider tokenProvider;
  final Future<String> Function() resolveUserId;
  final RtcPermissionGate permissionGate;
  final SessionCallProviderEventHub? eventHub;
  final LiveKitRoomPool _roomPool;
  final LiveKitRtcJoinGateway _joinGateway;
  final Map<String, Future<CallRoom>> _joinInFlight =
      <String, Future<CallRoom>>{};

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    if (request.providerKind != SessionCallProviderKind.livekit) {
      throw const CallProviderUnavailableFailure();
    }
    final effectiveUrl = serverUrl.trim();
    if (effectiveUrl.isEmpty) {
      throw const CallProviderUnavailableFailure(
        reasonCode: 'livekit_url_missing',
      );
    }

    final sessionId = request.sessionId;
    final inFlight = _joinInFlight[sessionId];
    if (inFlight != null) {
      return inFlight;
    }

    final joinFuture = _joinOnce(request, effectiveUrl);
    _joinInFlight[sessionId] = joinFuture;
    try {
      return await joinFuture;
    } finally {
      _joinInFlight.remove(sessionId);
    }
  }

  Future<CallRoom> _joinOnce(
    CallJoinRequest request,
    String effectiveUrl,
  ) async {
    await permissionGate.ensureGranted(
      needsCamera: request.callType == SessionCallType.videoCall,
    );

    await _roomPool.release(request.sessionId);

    final userId = await resolveUserId();
    final credentials = await tokenProvider.fetchCredentials(
      sessionId: request.sessionId,
      userId: userId,
    );

    if (credentials.token.isEmpty) {
      throw const RtcCallJoinFailure(reasonCode: 'missing_join_token');
    }

    final joinUrl = credentials.appId.trim().isNotEmpty
        ? credentials.appId.trim()
        : effectiveUrl;

    final handle = await _joinGateway.join(
      LiveKitJoinParams(
        serverUrl: joinUrl,
        token: credentials.token,
        enableVideo: request.callType == SessionCallType.videoCall,
      ),
    );

    _roomPool.remember(request.sessionId, handle);

    eventHub?.emit(SessionCallLocalChannelJoined(sessionId: request.sessionId));

    return CallRoom(
      sessionId: request.sessionId,
      channelId: credentials.channelId,
      token: credentials.token,
      extraData: {
        'providerKind': SessionCallProviderKind.livekit.name,
        'callType': request.callType.name,
        'role': request.role.name,
        'livekitIdentity': userId,
      },
    );
  }

  @override
  Future<CallRoom> joinSession(String sessionId) {
    throw const CallProviderUnavailableFailure();
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    await _roomPool.release(sessionId);
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _roomPool.release(sessionId);
  }

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {
    final handle = _roomPool.sessionFor(sessionId);
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
    final handle = _roomPool.sessionFor(sessionId);
    if (handle == null) {
      return;
    }
    await handle.setCameraEnabled(enabled);
  }

  @override
  Future<void> switchCamera(String sessionId) async {
    final handle = _roomPool.sessionFor(sessionId);
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
    final handle = _roomPool.sessionFor(sessionId);
    if (handle == null) {
      return;
    }
    await handle.setSpeakerEnabled(enabled);
  }
}
