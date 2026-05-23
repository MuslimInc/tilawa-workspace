import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_review_engagement.dart';

/// SharedPreferences keys for review engagement (do not rename after release).
abstract class AppReviewEngagementLocalDataSource {
  Future<AppReviewEngagement> read();

  Future<void> write(AppReviewEngagement engagement);
}

@LazySingleton(as: AppReviewEngagementLocalDataSource)
class AppReviewEngagementLocalDataSourceImpl
    implements AppReviewEngagementLocalDataSource {
  AppReviewEngagementLocalDataSourceImpl(this._prefs);

  static const String _prefix = 'app_review_engagement_';

  static const String _sessionCount = '${_prefix}session_count';
  static const String _activeDays = '${_prefix}active_days';
  static const String _listening = '${_prefix}listening';
  static const String _prayerVisits = '${_prefix}prayer_visits';
  static const String _favorites = '${_prefix}favorites';
  static const String _bookmarks = '${_prefix}bookmarks';
  static const String _promptCount = '${_prefix}prompt_count';
  static const String _firstSeen = '${_prefix}first_seen_ms';
  static const String _lastPrompt = '${_prefix}last_prompt_ms';
  static const String _lastSessionDay = '${_prefix}last_session_day';
  static const String _lastActiveDay = '${_prefix}last_active_day';

  final SharedPreferencesAsync _prefs;

  @override
  Future<AppReviewEngagement> read() async {
    return AppReviewEngagement(
      sessionCount: await _prefs.getInt(_sessionCount) ?? 0,
      distinctActiveDays: await _prefs.getInt(_activeDays) ?? 0,
      listeningCompletions: await _prefs.getInt(_listening) ?? 0,
      prayerTimesTabVisits: await _prefs.getInt(_prayerVisits) ?? 0,
      favoriteAdds: await _prefs.getInt(_favorites) ?? 0,
      bookmarkCreates: await _prefs.getInt(_bookmarks) ?? 0,
      promptCount: await _prefs.getInt(_promptCount) ?? 0,
      firstSeenAtMs: await _prefs.getInt(_firstSeen),
      lastPromptAtMs: await _prefs.getInt(_lastPrompt),
      lastSessionDayKey: await _prefs.getString(_lastSessionDay),
      lastActiveDayKey: await _prefs.getString(_lastActiveDay),
    );
  }

  @override
  Future<void> write(AppReviewEngagement engagement) async {
    await _prefs.setInt(_sessionCount, engagement.sessionCount);
    await _prefs.setInt(_activeDays, engagement.distinctActiveDays);
    await _prefs.setInt(_listening, engagement.listeningCompletions);
    await _prefs.setInt(_prayerVisits, engagement.prayerTimesTabVisits);
    await _prefs.setInt(_favorites, engagement.favoriteAdds);
    await _prefs.setInt(_bookmarks, engagement.bookmarkCreates);
    await _prefs.setInt(_promptCount, engagement.promptCount);
    if (engagement.firstSeenAtMs != null) {
      await _prefs.setInt(_firstSeen, engagement.firstSeenAtMs!);
    }
    if (engagement.lastPromptAtMs != null) {
      await _prefs.setInt(_lastPrompt, engagement.lastPromptAtMs!);
    }
    if (engagement.lastSessionDayKey != null) {
      await _prefs.setString(_lastSessionDay, engagement.lastSessionDayKey!);
    }
    if (engagement.lastActiveDayKey != null) {
      await _prefs.setString(_lastActiveDay, engagement.lastActiveDayKey!);
    }
  }
}
