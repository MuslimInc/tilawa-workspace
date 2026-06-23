import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('ValidateExternalMeetingUrl', () {
    test('accepts HTTPS meet and zoom links', () {
      check(
        ValidateExternalMeetingUrl.failureFor(
          'https://meet.google.com/abc-defg-hij',
        ),
      ).isNull();
      check(
        ValidateExternalMeetingUrl.failureFor(
          'https://zoom.us/j/123456789',
        ),
      ).isNull();
    });

    test('rejects non-HTTPS and malformed URLs', () {
      check(
        ValidateExternalMeetingUrl.failureFor('http://meet.google.com/x'),
      ).isNotNull();
      check(
        ValidateExternalMeetingUrl.failureFor('not-a-url'),
      ).isNotNull();
      check(
        ValidateExternalMeetingUrl.failureFor(
          'https://meet.google.com/x#frag',
        ),
      ).isNotNull();
    });

    test('allows empty to clear URL', () {
      check(ValidateExternalMeetingUrl.failureFor('')).isNull();
      check(ValidateExternalMeetingUrl.failureFor('   ')).isNull();
    });
  });

  group('SessionModePolicy.withoutExternalMeeting', () {
    test('does not fall back to voice when externalOnly loses external', () {
      const policy = SessionModePolicy.externalOnly;
      final adjusted = policy.withoutExternalMeeting();
      check(adjusted.isEnabled(SessionCallType.externalMeeting)).isFalse();
      check(adjusted.isEnabled(SessionCallType.voiceCall)).isFalse();
      check(adjusted.isEnabled(SessionCallType.videoCall)).isFalse();
    });

    test('freeBeta without URL keeps voice and video', () {
      const policy = SessionModePolicy.freeBeta;
      final adjusted = policy.withoutExternalMeeting();
      check(adjusted.isEnabled(SessionCallType.externalMeeting)).isFalse();
      check(adjusted.isEnabled(SessionCallType.voiceCall)).isTrue();
      check(adjusted.isEnabled(SessionCallType.videoCall)).isTrue();
    });
  });
}
