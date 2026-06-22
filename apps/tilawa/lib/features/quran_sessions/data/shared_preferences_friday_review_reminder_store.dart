import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Friday review banner dismissals across app restarts.
class SharedPreferencesFridayReviewReminderStore
    implements FridayReviewReminderStore {
  SharedPreferencesFridayReviewReminderStore(this._prefs);

  static const _keyPrefix = 'quran_sessions.friday_review_dismiss';

  final SharedPreferencesAsync _prefs;

  String _key(String teacherId, String nextWeekKey) =>
      '$_keyPrefix.$teacherId.$nextWeekKey';

  @override
  Future<bool> isDismissed({
    required String teacherId,
    required String nextWeekKey,
  }) async {
    final untilMs = await _prefs.getInt(_key(teacherId, nextWeekKey));
    if (untilMs == null) return false;
    return DateTime.now().isBefore(
      DateTime.fromMillisecondsSinceEpoch(untilMs),
    );
  }

  @override
  Future<void> dismiss({
    required String teacherId,
    required String nextWeekKey,
    required DateTime until,
  }) async {
    await _prefs.setInt(
      _key(teacherId, nextWeekKey),
      until.millisecondsSinceEpoch,
    );
  }
}
