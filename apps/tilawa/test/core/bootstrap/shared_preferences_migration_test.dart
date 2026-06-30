import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/bootstrap/shared_preferences_migration.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';

import '../../support/map_backed_shared_preferences_async.dart';

Future<SharedPreferences> _legacyPrefsWith(
  Map<String, Object> initial,
) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MapBackedSharedPreferencesAsync mapPrefs;

  setUp(() {
    mapPrefs = MapBackedSharedPreferencesAsync();
    sharedPreferencesAsyncFactoryForTesting = () => mapPrefs.prefs;
  });

  tearDown(() {
    sharedPreferencesAsyncFactoryForTesting = null;
    legacySharedPreferencesFactoryForTesting = null;
  });

  test('copies allowlisted legacy bools when async has no value', () async {
    legacySharedPreferencesFactoryForTesting = () =>
        _legacyPrefsWith(<String, Object>{
          PendingSessionRevokeStore.key: true,
          AppStartupTasks.legacyAudioPlayerBlocHydrationCleanupKey: false,
        });

    await migrateLegacySharedPreferencesToAsyncIfNeeded();

    expect(mapPrefs.store[PendingSessionRevokeStore.key], isTrue);
    expect(
      mapPrefs.store[AppStartupTasks.legacyAudioPlayerBlocHydrationCleanupKey],
      isFalse,
    );
    expect(
      mapPrefs.store[sharedPreferencesAsyncMigrationCompletedKey],
      isTrue,
    );
  });

  test('does not overwrite existing async allowlisted values', () async {
    mapPrefs = MapBackedSharedPreferencesAsync(<String, Object>{
      PendingSessionRevokeStore.key: false,
    });
    sharedPreferencesAsyncFactoryForTesting = () => mapPrefs.prefs;
    legacySharedPreferencesFactoryForTesting = () =>
        _legacyPrefsWith(<String, Object>{
          PendingSessionRevokeStore.key: true,
        });

    await migrateLegacySharedPreferencesToAsyncIfNeeded();

    expect(mapPrefs.store[PendingSessionRevokeStore.key], isFalse);
  });

  test('ignores non-allowlisted legacy keys', () async {
    legacySharedPreferencesFactoryForTesting = () =>
        _legacyPrefsWith(<String, Object>{
          'theme_mode': 'dark',
        });

    await migrateLegacySharedPreferencesToAsyncIfNeeded();

    expect(mapPrefs.store.containsKey('theme_mode'), isFalse);
    expect(
      mapPrefs.store[sharedPreferencesAsyncMigrationCompletedKey],
      isTrue,
    );
  });

  test('skips migration when completion flag already set', () async {
    mapPrefs = MapBackedSharedPreferencesAsync(<String, Object>{
      sharedPreferencesAsyncMigrationCompletedKey: true,
    });
    sharedPreferencesAsyncFactoryForTesting = () => mapPrefs.prefs;
    legacySharedPreferencesFactoryForTesting = () =>
        _legacyPrefsWith(<String, Object>{
          PendingSessionRevokeStore.key: true,
        });

    await migrateLegacySharedPreferencesToAsyncIfNeeded();

    expect(mapPrefs.store.containsKey(PendingSessionRevokeStore.key), isFalse);
  });
}
