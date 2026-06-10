import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for what's new progress (do not rename after release).
abstract interface class WhatsNewProgressLocalDataSource {
  Future<String?> readLastSeenReleaseId();

  Future<void> writeLastSeenReleaseId(String releaseId);

  Future<void> clear();
}

@LazySingleton(as: WhatsNewProgressLocalDataSource)
class WhatsNewProgressLocalDataSourceImpl
    implements WhatsNewProgressLocalDataSource {
  WhatsNewProgressLocalDataSourceImpl(this._prefs);

  static const String lastSeenReleaseIdKey = 'whats_new_last_seen_release_id';

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> readLastSeenReleaseId() {
    return _prefs.getString(lastSeenReleaseIdKey);
  }

  @override
  Future<void> writeLastSeenReleaseId(String releaseId) {
    return _prefs.setString(lastSeenReleaseIdKey, releaseId);
  }

  @override
  Future<void> clear() {
    return _prefs.remove(lastSeenReleaseIdKey);
  }
}
