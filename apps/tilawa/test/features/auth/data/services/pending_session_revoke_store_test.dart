import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';

import '../../../../support/map_backed_shared_preferences_async.dart';

void main() {
  late MapBackedSharedPreferencesAsync mapPrefs;

  setUp(() {
    mapPrefs = MapBackedSharedPreferencesAsync();
    PendingSessionRevokeStore.setPrefsFactoryForTesting(() => mapPrefs.prefs);
  });

  tearDown(() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
  });

  test('mark sets pending flag', () async {
    await PendingSessionRevokeStore.mark();

    expect(mapPrefs.store[PendingSessionRevokeStore.key], isTrue);
  });

  test('consume returns false when flag absent', () async {
    final consumed = await PendingSessionRevokeStore.consume();

    expect(consumed, isFalse);
    expect(mapPrefs.store.containsKey(PendingSessionRevokeStore.key), isFalse);
  });

  test('consume returns true once then clears flag', () async {
    mapPrefs = MapBackedSharedPreferencesAsync({
      PendingSessionRevokeStore.key: true,
    });
    PendingSessionRevokeStore.setPrefsFactoryForTesting(() => mapPrefs.prefs);

    expect(await PendingSessionRevokeStore.consume(), isTrue);
    expect(await PendingSessionRevokeStore.consume(), isFalse);
  });

  test('clear removes pending flag', () async {
    await PendingSessionRevokeStore.mark();
    await PendingSessionRevokeStore.clear();

    expect(mapPrefs.store.containsKey(PendingSessionRevokeStore.key), isFalse);
    expect(await PendingSessionRevokeStore.consume(), isFalse);
  });
}
