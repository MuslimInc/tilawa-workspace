import 'package:shared_preferences/shared_preferences.dart';

import '../domain/constants/khatma_reminder_constants.dart';

final class KhatmaReminderPreferences {
  const KhatmaReminderPreferences(this._prefs);

  final SharedPreferencesAsync _prefs;

  Future<bool> isDailyEnabled() async =>
      await _prefs.getBool(KhatmaReminderConstants.prefsEnabledKey) ?? false;

  Future<int> dailyHour() async =>
      await _prefs.getInt(KhatmaReminderConstants.prefsHourKey) ??
      KhatmaReminderConstants.defaultHour;

  Future<int> dailyMinute() async =>
      await _prefs.getInt(KhatmaReminderConstants.prefsMinuteKey) ??
      KhatmaReminderConstants.defaultMinute;

  Future<bool> dailyPromptShown() async =>
      await _prefs.getBool(KhatmaReminderConstants.prefsPromptShownKey) ??
      false;

  Future<bool> isBaqarahEnabled() async =>
      await _prefs.getBool(KhatmaReminderConstants.prefsBaqarahEnabledKey) ??
      false;

  Future<bool> isKahfEnabled() async =>
      await _prefs.getBool(KhatmaReminderConstants.prefsKahfEnabledKey) ??
      false;

  Future<bool> surahPromptShown() async =>
      await _prefs.getBool(KhatmaReminderConstants.prefsSurahPromptShownKey) ??
      false;

  Future<void> setDailyEnabled({required bool enabled}) =>
      _prefs.setBool(KhatmaReminderConstants.prefsEnabledKey, enabled);

  Future<void> setDailyTime({required int hour, required int minute}) async {
    await _prefs.setInt(KhatmaReminderConstants.prefsHourKey, hour);
    await _prefs.setInt(KhatmaReminderConstants.prefsMinuteKey, minute);
  }

  Future<void> setDailyPromptShown({required bool shown}) =>
      _prefs.setBool(KhatmaReminderConstants.prefsPromptShownKey, shown);

  Future<void> setBaqarahEnabled({required bool enabled}) =>
      _prefs.setBool(KhatmaReminderConstants.prefsBaqarahEnabledKey, enabled);

  Future<void> setKahfEnabled({required bool enabled}) =>
      _prefs.setBool(KhatmaReminderConstants.prefsKahfEnabledKey, enabled);

  Future<void> setSurahPromptShown({required bool shown}) =>
      _prefs.setBool(KhatmaReminderConstants.prefsSurahPromptShownKey, shown);

  Future<void> clearAll() async {
    await _prefs.remove(KhatmaReminderConstants.prefsEnabledKey);
    await _prefs.remove(KhatmaReminderConstants.prefsHourKey);
    await _prefs.remove(KhatmaReminderConstants.prefsMinuteKey);
    await _prefs.remove(KhatmaReminderConstants.prefsPromptShownKey);
    await _prefs.remove(KhatmaReminderConstants.prefsBaqarahEnabledKey);
    await _prefs.remove(KhatmaReminderConstants.prefsKahfEnabledKey);
    await _prefs.remove(KhatmaReminderConstants.prefsSurahPromptShownKey);
  }
}
