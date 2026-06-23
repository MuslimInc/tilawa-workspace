import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('RoutingSessionCallProvider', () {
    late RoutingSessionCallProvider router;
    CallJoinRequest? mockJoin;

    setUp(() {
      mockJoin = null;
      router = RoutingSessionCallProvider(
        external: ExternalMeetingCallProvider(
          getMeetingUrl: (_) async => 'https://meet.example.com/r',
          urlLauncher: (_) async {},
        ),
        mock: MockSessionCallProvider(onJoin: (request) => mockJoin = request),
      );
    });

    test('routes external join to external provider', () async {
      final room = await router.join(
        const CallJoinRequest(
          sessionId: 'session_1',
          role: SessionParticipantRole.student,
          callType: SessionCallType.externalMeeting,
          providerKind: SessionCallProviderKind.external,
          joinUrl: 'https://meet.example.com/room',
        ),
      );

      check(room.sessionId).equals('session_1');
      check(room.meetingUrl).equals('https://meet.example.com/room');
    });

    test('routes mock voice join to mock provider', () async {
      await router.join(
        const CallJoinRequest(
          sessionId: 'session_voice',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.mock,
          providerSessionId: 'session_voice',
        ),
      );

      check(mockJoin?.providerKind).equals(SessionCallProviderKind.mock);
      check(mockJoin?.callType).equals(SessionCallType.voiceCall);
    });

    test('rejects agora when provider not registered', () async {
      try {
        await router.join(
          const CallJoinRequest(
            sessionId: 'session_agora',
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

    test('rejects webrtc when provider not registered', () async {
      try {
        await router.join(
          const CallJoinRequest(
            sessionId: 'session_webrtc',
            role: SessionParticipantRole.student,
            callType: SessionCallType.videoCall,
            providerKind: SessionCallProviderKind.webrtc,
          ),
        );
        fail('expected CallProviderUnavailableFailure');
      } on CallProviderUnavailableFailure {
        // expected
      }
    });

    test('routes agora when provider is wired', () async {
      var agoraJoined = false;
      final wired = RoutingSessionCallProvider(
        external: router.external,
        mock: router.mock,
        agora: _RecordingProvider(
          onJoin: () => agoraJoined = true,
        ),
      );

      await wired.join(
        const CallJoinRequest(
          sessionId: 'session_agora',
          role: SessionParticipantRole.student,
          callType: SessionCallType.voiceCall,
          providerKind: SessionCallProviderKind.agora,
        ),
      );

      check(agoraJoined).isTrue();
    });

    test('forwards setMicrophoneMuted to registered agora provider', () async {
      bool? mutedValue;
      final wired = RoutingSessionCallProvider(
        external: router.external,
        mock: router.mock,
        agora: _RecordingProvider(
          onJoin: () {},
          onMute: (muted) => mutedValue = muted,
        ),
      );

      await wired.setMicrophoneMuted('session_agora', muted: true);

      check(mutedValue).equals(true);
    });
  });
}

class _RecordingProvider implements SessionCallProvider {
  const _RecordingProvider({
    required this.onJoin,
    this.onMute,
  });

  final void Function() onJoin;
  final void Function(bool muted)? onMute;

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    onJoin();
    return CallRoom(sessionId: request.sessionId);
  }

  @override
  Future<void> leaveSession(String sessionId) async {}

  @override
  Future<void> endSession(String sessionId) async {}

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {
    onMute?.call(muted);
  }
}
