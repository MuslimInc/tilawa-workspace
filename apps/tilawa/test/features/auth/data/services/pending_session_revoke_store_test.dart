import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mark sets pending flag', () async {
    await PendingSessionRevokeStore.mark();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PendingSessionRevokeStore.key), isTrue);
  });

  test('consume returns false when flag absent', () async {
    final consumed = await PendingSessionRevokeStore.consume();

    expect(consumed, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(PendingSessionRevokeStore.key), isFalse);
  });

  test('consume returns true once then clears flag', () async {
    SharedPreferences.setMockInitialValues({
      PendingSessionRevokeStore.key: true,
    });

    expect(await PendingSessionRevokeStore.consume(), isTrue);
    expect(await PendingSessionRevokeStore.consume(), isFalse);
  });
}
