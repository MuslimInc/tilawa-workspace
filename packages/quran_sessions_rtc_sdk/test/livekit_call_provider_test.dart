import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';
import 'package:quran_sessions_rtc_sdk/quran_sessions_rtc_sdk.dart';

void main() {
  group('LiveKitCallProvider', () {
    late _RecordingTokenProvider tokenProvider;
    late _FakeLiveKitJoinGateway joinGateway;
    late LiveKitRoomPool roomPool;

    LiveKitCallProvider buildProvider({
      String serverUrl = 'wss://livekit.test',
    }) {
      return LiveKitCallProvider(
        serverUrl: serverUrl,
        tokenProvider: tokenProvider,
        resolveUserId: () async => 'user_42',
        permissionGate: const _GrantAllPermissionGate(),
        roomPool: roomPool,
        joinGateway: joinGateway,
      );
    }

    setUp(() {
      tokenProvider = _RecordingTokenProvider();
      joinGateway = _FakeLiveKitJoinGateway();
      roomPool = LiveKitRoomPool();
    });

    test('rejects non-livekit join requests', () async {
      final provider = buildProvider();

      await expectLater(
        provider.join(
          const CallJoinRequest(
            sessionId: 'session_1',
            role: SessionParticipantRole.student,
            callType: SessionCallType.voiceCall,
            providerKind: SessionCallProviderKind.agora,
          ),
        ),
        throwsA(isA<CallProviderUnavailableFailure>()),
      );
    });

    test('rejects join when server url missing', () async {
      final provider = buildProvider(serverUrl: '');

      await expectLater(
        provider.join(
          const CallJoinRequest(
            sessionId: 'session_1',
            role: SessionParticipantRole.student,
            callType: SessionCallType.voiceCall,
            providerKind: SessionCallProviderKind.livekit,
          ),
        ),
        throwsA(isA<CallProviderUnavailableFailure>()),
      );
    });

    test('joins with server-issued token and room name', () async {
      tokenProvider.credentials = const RtcJoinCredentials(
        token: 'lk-token',
        channelId: 'room-9',
        uid: 0,
        appId: 'wss://cf.livekit.cloud',
      );

      final provider = buildProvider();
      final room = await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.videoCall,
          providerKind: SessionCallProviderKind.livekit,
        ),
      );

      check(joinGateway.lastParams?.serverUrl).equals('wss://cf.livekit.cloud');
      check(joinGateway.lastParams?.token).equals('lk-token');
      check(joinGateway.lastParams?.enableVideo).equals(true);
      check(room.extraData!['providerKind']).equals('livekit');
      check(roomPool.sessionFor('session_1')).isNotNull();
    });

    test('passes session and user id to token provider', () async {
      final provider = buildProvider();

      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_abc',
          role: SessionParticipantRole.teacher,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.livekit,
        ),
      );

      check(tokenProvider.lastSessionId).equals('session_abc');
      check(tokenProvider.lastUserId).equals('user_42');
    });

    test('leaveSession releases room pool entry', () async {
      tokenProvider.credentials = const RtcJoinCredentials(
        token: 'lk-token',
        channelId: 'room-1',
        uid: 0,
        appId: 'wss://livekit.test',
      );
      final provider = buildProvider();
      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.livekit,
        ),
      );

      await provider.leaveSession('session_1');

      check(roomPool.sessionFor('session_1')).isNull();
      check(joinGateway.releaseCount).equals(1);
    });
  });
}

class _RecordingTokenProvider implements CallTokenProvider {
  RtcJoinCredentials credentials = const RtcJoinCredentials(
    token: 'token',
    channelId: 'room',
    uid: 0,
    appId: 'wss://livekit.test',
  );

  String? lastSessionId;
  String? lastUserId;

  @override
  Future<RtcJoinCredentials> fetchCredentials({
    required String sessionId,
    required String userId,
  }) async {
    lastSessionId = sessionId;
    lastUserId = userId;
    return credentials;
  }
}

class _FakeLiveKitJoinGateway implements LiveKitRtcJoinGateway {
  LiveKitJoinParams? lastParams;
  var releaseCount = 0;

  @override
  Future<LiveKitRtcSessionHandle> join(LiveKitJoinParams params) async {
    lastParams = params;
    return _FakeLiveKitSessionHandle(onRelease: () => releaseCount++);
  }
}

class _FakeLiveKitSessionHandle implements LiveKitRtcSessionHandle {
  _FakeLiveKitSessionHandle({required this.onRelease});

  final void Function() onRelease;

  @override
  Future<void> leaveAndRelease() async {
    onRelease();
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {}

  @override
  Future<void> setCameraEnabled(bool enabled) async {}

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> setSpeakerEnabled(bool enabled) async {}

  @override
  Room? get room => null;
}

class _GrantAllPermissionGate extends RtcPermissionGate {
  const _GrantAllPermissionGate();

  @override
  Future<void> ensureGranted({required bool needsCamera}) async {}
}
