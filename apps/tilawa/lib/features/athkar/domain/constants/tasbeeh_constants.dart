class TasbeehConstants {
  const TasbeehConstants._();

  static const int categoryId = -100;
  static const String categoryIconName = 'prayer_times_rounded';

  static const String storageBoxName = 'athkar_tasbeeh_dhikr';

  static const int minTextLength = 1;
  static const int maxTextLength = 120;

  static const int defaultTargetCount = 33;
  static const int minTargetCount = 1;
  static const int maxTargetCount = 100000;

  static const String layoutPreferenceKey = 'tasbeeh_saved_layout_mode';

  static const String reminderChannelId = 'com.tilawa.app.tasbeeh_reminders';
  static const int reminderNotificationIdBase = 13000000;
  static const int reminderNotificationIdRange = 100000;
  static const String reminderPayloadPrefix = 'tasbeeh:dhikr:';
}
