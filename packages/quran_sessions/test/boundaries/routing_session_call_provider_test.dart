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
      } on CallProviderUnavailableFailure catch (e) {
        check(e.reasonCode).equals('agora_not_registered');
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

    test('routes webrtc when provider is wired', () async {
      var webrtcJoined = false;
      final wired = RoutingSessionCallProvider(
        external: router.external,
        mock: router.mock,
        webrtc: _RecordingProvider(onJoin: () => webrtcJoined = true),
      );

      await wired.join(
        const CallJoinRequest(
          sessionId: 'session_webrtc',
          role: SessionParticipantRole.student,
          callType: SessionCallType.videoCall,
          providerKind: SessionCallProviderKind.webrtc,
        ),
      );

      check(webrtcJoined).isTrue();
    });

    test('leaveSession fans out to every registered provider', () async {
      final events = <String>[];
      final wired = RoutingSessionCallProvider(
        external: _RecordingProvider(
          onJoin: () {},
          onLeave: () => events.add('external'),
        ),
        mock: _RecordingProvider(
          onJoin: () {},
          onLeave: () => events.add('mock'),
        ),
        agora: _RecordingProvider(
          onJoin: () {},
          onLeave: () => events.add('agora'),
        ),
        webrtc: _RecordingProvider(
          onJoin: () {},
          onLeave: () => events.add('webrtc'),
        ),
      );

      await wired.leaveSession('session_1');

      check(events).unorderedEquals(['external', 'mock', 'agora', 'webrtc']);
    });

    test('endSession fans out to every registered provider', () async {
      final events = <String>[];
      final wired = RoutingSessionCallProvider(
        external: _RecordingProvider(
          onJoin: () {},
          onEnd: () => events.add('external'),
        ),
        mock: _RecordingProvider(
          onJoin: () {},
          onEnd: () => events.add('mock'),
        ),
        agora: _RecordingProvider(
          onJoin: () {},
          onEnd: () => events.add('agora'),
        ),
      );

      await wired.endSession('session_1');

      check(events).unorderedEquals(['external', 'mock', 'agora']);
    });
  });

  group('CallProviderAdapter', () {
    test('joinSession resolves request then delegates join', () async {
      CallJoinRequest? resolved;
      final adapter = CallProviderAdapter(
        _RecordingProvider(onJoin: () {}),
        resolveRequest: (sessionId) async {
          resolved = CallJoinRequest(
            sessionId: sessionId,
            role: SessionParticipantRole.student,
            callType: SessionCallType.voiceCall,
            providerKind: SessionCallProviderKind.mock,
          );
          return resolved!;
        },
      );

      final room = await adapter.joinSession('session_adapter');

      check(resolved?.sessionId).equals('session_adapter');
      check(room.sessionId).equals('session_adapter');
    });

    test('joinSession fails when resolver is not injected', () async {
      final adapter = CallProviderAdapter(_RecordingProvider(onJoin: () {}));

      await expectLater(
        () async => adapter.joinSession('session_adapter'),
        throwsA(isA<CallProviderUnavailableFailure>()),
      );
    });

    test('leave and end delegate to inner provider', () async {
      final events = <String>[];
      final adapter = CallProviderAdapter(
        _RecordingProvider(
          onJoin: () {},
          onLeave: () => events.add('leave'),
          onEnd: () => events.add('end'),
        ),
      );

      await adapter.leaveSession('session_adapter');
      await adapter.endSession('session_adapter');

      check(events).deepEquals(['leave', 'end']);
    });
  });
}

class _RecordingProvider implements SessionCallProvider {
  const _RecordingProvider({
    required this.onJoin,
    this.onMute,
    this.onLeave,
    this.onEnd,
  });

  final void Function() onJoin;
  final void Function(bool muted)? onMute;
  final void Function(bool enabled)? onMicrophoneEnabled = null;
  final void Function(bool enabled)? onCameraEnabled = null;
  final void Function()? onSwitchCamera = null;
  final void Function(bool enabled)? onSpeakerEnabled = null;
  final void Function()? onLeave;
  final void Function()? onEnd;

  @override
  Future<CallRoom> join(CallJoinRequest request) async {
    onJoin();
    return CallRoom(sessionId: request.sessionId);
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    onLeave?.call();
  }

  @override
  Future<void> endSession(String sessionId) async {
    onEnd?.call();
  }

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {
    onMute?.call(muted);
  }

  @override
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    onMicrophoneEnabled?.call(enabled);
  }

  @override
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    onCameraEnabled?.call(enabled);
  }

  @override
  Future<void> switchCamera(String sessionId) async {
    onSwitchCamera?.call();
  }

  @override
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    onSpeakerEnabled?.call(enabled);
  }
}
