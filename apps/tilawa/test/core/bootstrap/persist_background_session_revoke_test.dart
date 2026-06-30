import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';

import '../../support/map_backed_shared_preferences_async.dart';

void main() {
  late MapBackedSharedPreferencesAsync mapPrefs;

  setUp(() {
    mapPrefs = MapBackedSharedPreferencesAsync();
    PendingSessionRevokeStore.setPrefsFactoryForTesting(() => mapPrefs.prefs);
  });

  tearDown(() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
  });

  test('ignores unrelated background payloads', () async {
    await persistBackgroundSessionRevokeIfNeeded(const {'type': 'reciter'});

    expect(mapPrefs.store[PendingSessionRevokeStore.key], isNull);
  });

  test('marks pending revoke for session_revoked payloads', () async {
    await persistBackgroundSessionRevokeIfNeeded(
      const {'actionType': 'session_revoked'},
    );

    expect(mapPrefs.store[PendingSessionRevokeStore.key], isTrue);
  });
}
