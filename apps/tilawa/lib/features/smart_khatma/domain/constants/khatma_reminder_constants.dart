abstract final class KhatmaReminderConstants {
  static const String dailyChannelId = 'com.tilawa.app.khatma_reminders';
  static const String surahChannelId = 'com.tilawa.app.khatma_surah_reminders';

  static const int dailyNotificationId = 14000001;
  static const int baqarahNotificationId = 14000002;
  static const int kahfNotificationId = 14000003;

  static const String dailyPayload = 'khatma:daily';
  static const String baqarahPayload = 'khatma:surah:2';
  static const String kahfPayload = 'khatma:surah:18';

  static const String prefsEnabledKey = 'smart_khatma.reminder.enabled';
  static const String prefsHourKey = 'smart_khatma.reminder.hour';
  static const String prefsMinuteKey = 'smart_khatma.reminder.minute';
  static const String prefsPromptShownKey =
      'smart_khatma.reminder.prompt_shown';
  static const String prefsBaqarahEnabledKey =
      'smart_khatma.reminder.baqarah_enabled';
  static const String prefsKahfEnabledKey =
      'smart_khatma.reminder.kahf_enabled';
  static const String prefsSurahPromptShownKey =
      'smart_khatma.reminder.surah_prompt_shown';

  static const int defaultHour = 9;
  static const int defaultMinute = 0;

  static const int baqarahSurah = 2;
  static const int kahfSurah = 18;
}
