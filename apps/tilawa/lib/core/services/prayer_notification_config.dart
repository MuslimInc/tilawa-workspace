import '../../features/prayer_times/domain/entities/prayer_time_entity.dart';

/// Centralized configuration for prayer time notifications.
///
/// Owns every constant used by the prayer-notification feature: notification
/// channel IDs, static and dynamic notification IDs, scheduling window,
/// SharedPreferences keys, payload keys, and the log tag. No magic numbers or
/// string literals live outside this class.
final class PrayerNotificationConfig {
  PrayerNotificationConfig._();

  // --- Notification Channels ---
  static const String channelId = 'com.tilawa.app.prayer';
  static const String adhanChannelId = 'com.tilawa.app.prayer_adhan';
  static const String channelName = 'Prayer Times';
  static const String adhanChannelName = 'Prayer Times (Adhan)';
  static const String channelDescription =
      'Reminders for the five daily prayer times';
  static const String adhanChannelDescription =
      'Prayer time reminders that play the adhan sound';

  // --- Adhan sound ---
  /// Filename used in both `android/app/src/main/res/raw/` and the iOS bundle.
  static const String adhanSoundRawName = 'adhan';
  static const String adhanSoundFilename = 'adhan.mp3';
  static const String adhanAssetPath = 'assets/audio/adhan.mp3';

  /// Bumped whenever the adhan channel configuration changes so the channel
  /// is deleted and recreated on existing installs (Android channel sound lock).
  static const String adhanChannelVersionKey =
      'prayer_notifications_adhan_channel_version';
  static const int adhanChannelVersion = 2;

  // --- Notification IDs ---
  /// Static IDs (test / debug): fajr=2001, sunrise=2002, dhuhr=2003,
  /// asr=2004, maghrib=2005, isha=2006.
  static const int staticIdBase = 2001;

  /// Dynamic IDs: [dynamicIdBase] + (dayOffset * 10) + prayerType.index.
  /// Prayer indexes mirror the `PrayerType` enum (fajr=0 ... isha=5).
  static const int dynamicIdBase = 20000000;

  // --- Scheduling ---
  /// Number of days of prayer times to schedule ahead.
  /// 14 days × ~6 prayers ≈ 84 alarms — well under the iOS 64 limit per app
  /// which Tilawa does not yet target, and trivial for Android.
  static const int scheduleDaysAhead = 14;

  // --- Deduplication & fingerprint ---
  // SharedPreferences keys — must not change after first release without a
  // migration; older devices will silently re-schedule on the next run.
  static const String dedupDateKey = 'prayer_notifications_last_scheduled_date';
  static const String settingsFingerprintKey =
      'prayer_notifications_settings_fingerprint';
  static const String lastTimezoneKey = 'prayer_notifications_last_tz';

  // --- Payload keys ---
  static const String payloadTypeKey = 'type';
  static const String payloadTypeValue = 'prayer';
  static const String payloadPrayerKey = 'prayer';
  static const String payloadDateKey = 'date';

  // --- Logging ---
  static const String logTag = '[PrayerTimes]';

  // --- ID helpers ---
  /// Returns the static notification ID for [prayer].
  static int staticId(PrayerType prayer) => staticIdBase + prayer.index;

  /// Returns the dynamic notification ID for the alarm [dayOffset] days from
  /// today for [prayer].
  static int dynamicId(int dayOffset, PrayerType prayer) =>
      dynamicIdBase + (dayOffset * 10) + prayer.index;

  /// Inclusive upper bound of dynamic IDs that may be in use given the current
  /// schedule window. Used by cancellation paths that cancel by ID range.
  static int get dynamicIdRangeEndExclusive =>
      dynamicIdBase + (scheduleDaysAhead * 10);
}
