import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Options shared by DI and direct [SharedPreferencesAsync] construction.
const SharedPreferencesOptions tilawaSharedPreferencesOptions =
    SharedPreferencesOptions();

/// Key in [SharedPreferencesAsync] marking legacy prefs migration complete.
///
/// Do not rename after release — migration is skipped when this key exists.
const String sharedPreferencesAsyncMigrationCompletedKey =
    'tilawa_shared_preferences_async_migration_completed';

/// Legacy keys still written via [SharedPreferences.getInstance] before the
/// async migration — keep in sync with [PendingSessionRevokeStore.key] and
/// [AppStartupTasks.legacyAudioPlayerBlocHydrationCleanupKey].
///
/// At ~50–100 Play users we skip the package's blind legacy→async copy (it can
/// overwrite newer async values) and migrate only these two bool flags.
const Set<String> legacySharedPreferencesMigrationAllowlist = {
  'pending_session_revoke',
  'audio_player_bloc_hydration_removed_v1',
};

@visibleForTesting
SharedPreferencesAsync Function()? sharedPreferencesAsyncFactoryForTesting;

@visibleForTesting
Future<SharedPreferences> Function()? legacySharedPreferencesFactoryForTesting;

/// Copies allowlisted legacy [SharedPreferences] keys into
/// [SharedPreferencesAsync] once, without overwriting existing async values.
///
/// Safe to call on every launch; no-op after
/// [sharedPreferencesAsyncMigrationCompletedKey] is set.
Future<void> migrateLegacySharedPreferencesToAsyncIfNeeded() async {
  final SharedPreferencesAsync asyncPrefs =
      sharedPreferencesAsyncFactoryForTesting?.call() ??
      SharedPreferencesAsync(options: tilawaSharedPreferencesOptions);

  if (await asyncPrefs.containsKey(
    sharedPreferencesAsyncMigrationCompletedKey,
  )) {
    return;
  }

  final SharedPreferences legacy =
      await (legacySharedPreferencesFactoryForTesting?.call() ??
          SharedPreferences.getInstance());
  await legacy.reload();

  for (final key in legacySharedPreferencesMigrationAllowlist) {
    if (!legacy.containsKey(key)) {
      continue;
    }
    if (await asyncPrefs.containsKey(key)) {
      continue;
    }

    final bool? value = legacy.getBool(key);
    if (value != null) {
      await asyncPrefs.setBool(key, value);
    }
  }

  await asyncPrefs.setBool(sharedPreferencesAsyncMigrationCompletedKey, true);
}
