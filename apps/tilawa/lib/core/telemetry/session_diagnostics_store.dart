import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/shared_preferences_migration.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_snapshot.dart';

/// Persists [SessionDiagnosticsSnapshot] so AppExitInfo / ANR events on the
/// *next* cold start can still recover pre-death playback/session context.
abstract final class SessionDiagnosticsStore {
  static const String prefsKey = 'tilawa_session_diagnostics_v1';

  @visibleForTesting
  static SharedPreferencesAsync? prefsOverride;

  static SharedPreferencesAsync get _prefs =>
      prefsOverride ??
      SharedPreferencesAsync(options: tilawaSharedPreferencesOptions);

  static Future<void> save(SessionDiagnosticsSnapshot snapshot) async {
    await _prefs.setString(prefsKey, snapshot.encode());
  }

  static Future<SessionDiagnosticsSnapshot?> load() async {
    return SessionDiagnosticsSnapshot.tryDecode(
      await _prefs.getString(prefsKey),
    );
  }

  @visibleForTesting
  static Future<void> clearForTesting() async {
    await _prefs.remove(prefsKey);
  }
}
