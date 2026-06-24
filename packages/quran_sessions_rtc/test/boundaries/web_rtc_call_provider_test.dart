import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

void main() {
  group('WebRtcCallProvider', () {
    const provider = WebRtcCallProvider(
      tokenProvider: _FakeTokenProvider(),
      signalingServerUrl: 'wss://signal.example.com',
    );

    test('rejects non-webrtc join requests', () async {
      try {
        await provider.join(
          const CallJoinRequest(
            sessionId: 's1',
            role: SessionParticipantRole.student,
            callType: SessionCallType.voiceCall,
            providerKind: SessionCallProviderKind.agora,
          ),
        );
        fail('expected CallProviderUnavailableFailure');
      } on CallProviderUnavailableFailure {
        // expected
      }
    });

    test('fails gracefully when signaling is not implemented', () async {
      try {
        await provider.join(
          const CallJoinRequest(
            sessionId: 's1',
            role: SessionParticipantRole.student,
            callType: SessionCallType.voiceCall,
            providerKind: SessionCallProviderKind.webrtc,
          ),
        );
        fail('expected WebRtcSignalingUnavailableFailure');
      } on WebRtcSignalingUnavailableFailure {
        // expected
      }
    });

    test('rejects join when signaling url is blank', () async {
      const blankProvider = WebRtcCallProvider(
        tokenProvider: _FakeTokenProvider(),
        signalingServerUrl: '   ',
      );

      await expectLater(
        blankProvider.join(
          const CallJoinRequest(
            sessionId: 's1',
            role: SessionParticipantRole.student,
            callType: SessionCallType.voiceCall,
            providerKind: SessionCallProviderKind.webrtc,
          ),
        ),
        throwsA(isA<WebRtcSignalingUnavailableFailure>()),
      );
    });

    test('joinSession is unavailable until signaling ships', () async {
      await expectLater(
        () async => provider.joinSession('s1'),
        throwsA(isA<WebRtcSignalingUnavailableFailure>()),
      );
    });

    test('leave end and mute are no-ops for MVP stub', () async {
      await provider.leaveSession('s1');
      await provider.endSession('s1');
      await provider.setMicrophoneMuted('s1', muted: true);
    });
  });
}

class _FakeTokenProvider implements CallTokenProvider {
  const _FakeTokenProvider();

  @override
  Future<RtcJoinCredentials> fetchCredentials({
    required String sessionId,
    required String userId,
  }) async => const RtcJoinCredentials(
    token: 'token',
    channelId: 'channel',
    uid: 42,
    appId: 'app-id',
  );
}
