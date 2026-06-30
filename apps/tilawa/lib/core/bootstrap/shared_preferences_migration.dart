import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

/// Options shared by DI and direct [SharedPreferencesAsync] construction.
const SharedPreferencesOptions tilawaSharedPreferencesOptions =
    SharedPreferencesOptions();

/// Key in [SharedPreferencesAsync] marking legacy prefs migration complete.
///
/// Do not rename after release — migration is skipped when this key exists.
const String sharedPreferencesAsyncMigrationCompletedKey =
    'tilawa_shared_preferences_async_migration_completed';

/// Copies legacy [SharedPreferences] into [SharedPreferencesAsync] once.
///
/// Safe to call on every launch; no-op after [migrationCompletedKey] is set.
Future<void> migrateLegacySharedPreferencesToAsyncIfNeeded() async {
  final SharedPreferences legacy = await SharedPreferences.getInstance();
  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: legacy,
    sharedPreferencesAsyncOptions: tilawaSharedPreferencesOptions,
    migrationCompletedKey: sharedPreferencesAsyncMigrationCompletedKey,
  );
}
