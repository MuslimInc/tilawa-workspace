import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

void main() {
  group('AgoraCallProvider', () {
    late _RecordingTokenProvider tokenProvider;
    late _FakeAgoraRtcJoinGateway joinGateway;
    late AgoraRtcEnginePool enginePool;

    AgoraCallProvider buildProvider() {
      return AgoraCallProvider(
        appId: 'fallback-app-id',
        tokenProvider: tokenProvider,
        resolveUserId: () async => 'user_42',
        permissionGate: const _GrantAllPermissionGate(),
        enginePool: enginePool,
        joinGateway: joinGateway,
      );
    }

    setUp(() {
      tokenProvider = _RecordingTokenProvider();
      joinGateway = _FakeAgoraRtcJoinGateway();
      enginePool = AgoraRtcEnginePool();
    });

    test('rejects non-agora join requests', () async {
      final provider = buildProvider();

      await expectLater(
        provider.join(
          const CallJoinRequest(
            sessionId: 'session_1',
            role: SessionParticipantRole.student,
            callType: SessionCallType.voiceCall,
            providerKind: SessionCallProviderKind.webrtc,
          ),
        ),
        throwsA(isA<CallProviderUnavailableFailure>()),
      );
    });

    test('uses server-issued uid verbatim when joining channel', () async {
      tokenProvider.credentials = const RtcJoinCredentials(
        token: 'rtc-token',
        channelId: 'channel-9',
        uid: 918273,
        appId: 'cf-app-id',
      );

      final provider = buildProvider();
      final room = await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      check(joinGateway.lastParams?.uid).equals(918273);
      check(joinGateway.lastParams?.channelId).equals('channel-9');
      check(joinGateway.lastParams?.token).equals('rtc-token');
      check(joinGateway.lastParams?.appId).equals('cf-app-id');
      check(room.extraData!['agoraUid']).equals(918273);
      check(enginePool.sessionFor('session_1')).isNotNull();
    });

    test('passes session and user id to token provider', () async {
      final provider = buildProvider();

      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_abc',
          role: SessionParticipantRole.teacher,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      check(tokenProvider.lastSessionId).equals('session_abc');
      check(tokenProvider.lastUserId).equals('user_42');
    });

    test('does not remember session when join gateway fails', () async {
      joinGateway.shouldFail = true;
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
        throwsA(isA<RtcCallJoinFailure>()),
      );

      check(enginePool.sessionFor('session_1')).isNull();
    });

    test('leaveSession releases pooled handle', () async {
      final provider = buildProvider();
      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      await provider.leaveSession('session_1');

      check(joinGateway.lastHandle!.released).equals(true);
      check(enginePool.sessionFor('session_1')).isNull();
    });

    test('setMicrophoneMuted forwards mute state to active handle', () async {
      final provider = buildProvider();
      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      await provider.setMicrophoneMuted('session_1', muted: true);

      check(joinGateway.lastHandle!.microphoneMuted).equals(true);
    });

    test('setCameraEnabled forwards to active handle', () async {
      final provider = buildProvider();
      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.videoCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      await provider.setCameraEnabled('session_1', enabled: false);

      check(joinGateway.lastHandle!.cameraEnabled).equals(false);
    });

    test('switchCamera forwards to active handle', () async {
      final provider = buildProvider();
      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.videoCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      await provider.switchCamera('session_1');

      check(joinGateway.lastHandle!.switchedCamera).isTrue();
    });

    test('setSpeakerEnabled forwards to active handle', () async {
      final provider = buildProvider();
      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      await provider.setSpeakerEnabled('session_1', enabled: true);

      check(joinGateway.lastHandle!.speakerEnabled).equals(true);
    });

    test('rejects join when fallback app id is blank', () async {
      final provider = AgoraCallProvider(
        appId: '   ',
        tokenProvider: tokenProvider,
        resolveUserId: () async => 'user_42',
        permissionGate: const _GrantAllPermissionGate(),
        enginePool: enginePool,
        joinGateway: joinGateway,
      );

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

    test('rejects join when server token is empty', () async {
      tokenProvider.credentials = const RtcJoinCredentials(
        token: '',
        channelId: 'channel-1',
        uid: 1001,
        appId: 'app-id',
      );
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
        throwsA(isA<RtcCallJoinFailure>()),
      );
    });

    test(
      'falls back to provider app id when credentials omit app id',
      () async {
        tokenProvider.credentials = const RtcJoinCredentials(
          token: 'rtc-token',
          channelId: 'channel-1',
          uid: 1001,
          appId: '',
        );
        final provider = buildProvider();

        await provider.join(
          const CallJoinRequest(
            sessionId: 'session_1',
            role: SessionParticipantRole.student,
            callType: SessionCallType.videoCall,
            providerKind: SessionCallProviderKind.agora,
          ),
        );

        check(joinGateway.lastParams?.appId).equals('fallback-app-id');
        check(joinGateway.lastParams?.enableVideo).equals(true);
      },
    );

    test('joinSession is unavailable on agora provider', () async {
      final provider = buildProvider();

      await expectLater(
        () async => provider.joinSession('session_1'),
        throwsA(isA<CallProviderUnavailableFailure>()),
      );
    });

    test('endSession releases pooled handle', () async {
      final provider = buildProvider();
      await provider.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      await provider.endSession('session_1');

      check(joinGateway.lastHandle!.released).equals(true);
      check(enginePool.sessionFor('session_1')).isNull();
    });

    test('setMicrophoneMuted ignores unknown session', () async {
      final provider = buildProvider();

      await provider.setMicrophoneMuted('missing', muted: true);

      check(joinGateway.lastHandle).isNull();
    });

    test(
      'releases stale pooled session before rejoining same session',
      () async {
        final provider = buildProvider();
        const request = CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        );

        await provider.join(request);
        final firstHandle = joinGateway.lastHandle;
        check(firstHandle).isNotNull();

        await provider.join(request);

        check(firstHandle!.released).isTrue();
        check(joinGateway.lastHandle).isNotNull();
        check(joinGateway.lastHandle == firstHandle).isFalse();
        check(enginePool.sessionFor('session_1')).isNotNull();
      },
    );

    test('deduplicates concurrent join for the same session id', () async {
      joinGateway.joinDelay = const Duration(milliseconds: 50);
      final provider = buildProvider();
      const request = CallJoinRequest(
        sessionId: 'session_1',
        role: SessionParticipantRole.student,
        callType: SessionCallType.voiceCall,
        providerKind: SessionCallProviderKind.agora,
      );

      final first = provider.join(request);
      final second = provider.join(request);

      final rooms = await Future.wait([first, second]);

      check(rooms[0].sessionId).equals('session_1');
      check(rooms[1].sessionId).equals('session_1');
      check(joinGateway.joinCount).equals(1);
    });
  });

  group('LiveAgoraRtcJoinGateway', () {
    test('returns live handle when join runner succeeds', () async {
      final gateway = LiveAgoraRtcJoinGateway(
        joinRunner: (_, params) async {
          check(params.channelId).equals('channel-9');
        },
        releaseEngine: (_) async {},
      );

      final handle = await gateway.join(
        const AgoraRtcJoinParams(
          appId: 'app',
          token: 'tok',
          channelId: 'channel-9',
          uid: 424242,
          enableVideo: false,
        ),
      );

      check(handle).isA<LiveAgoraRtcSessionHandle>();
    });

    test('releases engine when join runner fails', () async {
      var releaseCount = 0;
      final gateway = LiveAgoraRtcJoinGateway(
        joinRunner: (_, params) async {
          check(params.uid).equals(424242);
          throw const RtcCallJoinFailure(reasonCode: 'join_failed');
        },
        releaseEngine: (_) async {
          releaseCount++;
        },
      );

      await expectLater(
        gateway.join(
          const AgoraRtcJoinParams(
            appId: 'app',
            token: 'tok',
            channelId: 'ch',
            uid: 424242,
            enableVideo: false,
          ),
        ),
        throwsA(isA<RtcCallJoinFailure>()),
      );

      check(releaseCount).equals(1);
    });

    test('maps Agora join rejection (-17) to join_channel_rejected', () {
      final failure = mapAgoraRtcJoinFailure(AgoraRtcException(code: -17));

      check(failure.reasonCode).equals('join_channel_rejected');
    });
  });
}

class _GrantAllPermissionGate extends RtcPermissionGate {
  const _GrantAllPermissionGate();

  @override
  Future<void> ensureGranted({required bool needsCamera}) async {}
}

class _RecordingTokenProvider implements CallTokenProvider {
  RtcJoinCredentials credentials = const RtcJoinCredentials(
    token: 'rtc-token',
    channelId: 'channel-1',
    uid: 1001,
    appId: 'app-id',
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

class _FakeAgoraRtcJoinGateway implements AgoraRtcJoinGateway {
  AgoraRtcJoinParams? lastParams;
  _FakeAgoraRtcSessionHandle? lastHandle;
  bool shouldFail = false;
  Duration joinDelay = Duration.zero;
  int joinCount = 0;

  @override
  Future<AgoraRtcSessionHandle> join(AgoraRtcJoinParams params) async {
    joinCount++;
    lastParams = params;
    if (joinDelay > Duration.zero) {
      await Future<void>.delayed(joinDelay);
    }
    if (shouldFail) {
      throw const RtcCallJoinFailure(reasonCode: 'join_failed');
    }
    final handle = _FakeAgoraRtcSessionHandle();
    lastHandle = handle;
    return handle;
  }
}

class _FakeAgoraRtcSessionHandle implements AgoraRtcSessionHandle {
  bool released = false;
  bool? microphoneMuted;
  bool? cameraEnabled;
  bool? speakerEnabled;
  bool switchedCamera = false;

  @override
  Future<void> leaveAndRelease({bool retainEngine = false}) async {
    released = !retainEngine;
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    microphoneMuted = muted;
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    cameraEnabled = enabled;
  }

  @override
  Future<void> switchCamera() async {
    switchedCamera = true;
  }

  @override
  Future<void> setSpeakerEnabled(bool enabled) async {
    speakerEnabled = enabled;
  }

  @override
  RtcEngine? get engine => null;
}
