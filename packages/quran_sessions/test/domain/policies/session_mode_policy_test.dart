import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('SessionModePolicy', () {
    test('withoutExternalMeeting keeps mock voice and video on freeBeta', () {
      final effective = SessionModePolicy.freeBeta.withoutExternalMeeting();

      check(effective.isEnabled(SessionCallType.externalMeeting)).isFalse();
      check(effective.isEnabled(SessionCallType.voiceCall)).isTrue();
      check(effective.isEnabled(SessionCallType.videoCall)).isTrue();
    });

    test('defaultCallType uses voice when teacher has no meeting URL', () {
      final callType = SessionModePolicy.defaultCallType(
        policy: SessionModePolicy.freeBeta,
        externalMeetingUrl: null,
      );

      check(callType).equals(SessionCallType.voiceCall);
    });

    test('defaultCallType uses external when teacher has meeting URL', () {
      final callType = SessionModePolicy.defaultCallType(
        policy: SessionModePolicy.freeBeta,
        externalMeetingUrl: 'https://meet.example.com/room',
      );

      check(callType).equals(SessionCallType.externalMeeting);
    });

    test('videoOnly enables video and defaults to video call type', () {
      const policy = SessionModePolicy.videoOnly;

      check(policy.isEnabled(SessionCallType.videoCall)).isTrue();
      check(policy.isEnabled(SessionCallType.voiceCall)).isFalse();
      check(policy.isEnabled(SessionCallType.externalMeeting)).isFalse();
      check(
        SessionModePolicy.defaultCallType(
          policy: policy,
          externalMeetingUrl: 'https://meet.example.com/room',
        ),
      ).equals(SessionCallType.videoCall);
    });
  });
}
