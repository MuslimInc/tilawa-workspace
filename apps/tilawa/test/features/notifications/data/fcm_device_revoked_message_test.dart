import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/notifications/data/fcm_device_revoked_message.dart';

void main() {
  test('matches device_revoked via type or actionType', () {
    check(isDeviceRevokedFcmMessage({'type': 'device_revoked'})).isTrue();
    check(
      isDeviceRevokedFcmMessage({'actionType': 'DEVICE_REVOKED'}),
    ).isTrue();
  });

  test('ignores other control messages', () {
    check(isDeviceRevokedFcmMessage({'type': 'session_taken_over'})).isFalse();
    check(isDeviceRevokedFcmMessage({'type': 'session_revoked'})).isFalse();
    check(isDeviceRevokedFcmMessage(const {})).isFalse();
  });
}
