import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ignores unrelated background payloads', () async {
    await persistBackgroundSessionRevokeIfNeeded(const {'type': 'reciter'});

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PendingSessionRevokeStore.key), isNull);
  });

  test('marks pending revoke for session_revoked payloads', () async {
    await persistBackgroundSessionRevokeIfNeeded(
      const {'actionType': 'session_revoked'},
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PendingSessionRevokeStore.key), isTrue);
  });
}
