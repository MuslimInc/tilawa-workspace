import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/notifications/data/fcm_session_revoked_message.dart';

void main() {
  test('matches type session_revoked', () {
    expect(
      isSessionRevokedFcmMessage(const {'type': 'session_revoked'}),
      isTrue,
    );
  });

  test('matches actionType session_revoked', () {
    expect(
      isSessionRevokedFcmMessage(const {'actionType': 'SESSION_REVOKED'}),
      isTrue,
    );
  });

  test('rejects unrelated payloads', () {
    expect(
      isSessionRevokedFcmMessage(const {
        'type': 'teacher_application_reviewed',
      }),
      isFalse,
    );
    expect(isSessionRevokedFcmMessage(const {}), isFalse);
  });
}
