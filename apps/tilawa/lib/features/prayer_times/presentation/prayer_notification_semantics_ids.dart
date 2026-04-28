/// Stable semantic identifiers for Prayer Times Notifications E2E tests.
///
/// Add these to [Semantics.identifier] on the relevant widgets so Maestro can
/// locate interactive elements independently of locale or UI text changes.
///
/// Usage in Dart:
/// ```dart
/// Semantics(
///   identifier: PrayerNotificationSemanticsIds.globalToggle,
///   child: _SettingsSwitch(...),
/// )
/// ```
///
/// Usage in Maestro YAML:
/// ```yaml
/// - tapOn:
///     id: "prayer_notifications_global_toggle"
/// ```
abstract final class PrayerNotificationSemanticsIds {
  /// Bottom-nav tab that navigates to the Prayer Times screen.
  static const String prayerTimesTab = 'prayer_times_tab';

  /// Settings icon-button in the Prayer Times AppBar that opens the settings
  /// bottom sheet.
  static const String prayerSettingsButton = 'prayer_settings_button';

  /// The "Prayer Notifications" section header inside the settings sheet.
  static const String notificationsSection = 'prayer_notifications_section';

  /// Global "All Prayer Notifications" toggle switch.
  static const String globalToggle = 'prayer_notifications_global_toggle';

  /// Per-prayer notification toggles.
  static const String fajrToggle = 'prayer_notification_fajr_toggle';
  static const String dhuhrToggle = 'prayer_notification_dhuhr_toggle';
  static const String asrToggle = 'prayer_notification_asr_toggle';
  static const String maghribToggle = 'prayer_notification_maghrib_toggle';
  static const String ishaToggle = 'prayer_notification_isha_toggle';

  /// Segmented button for choosing how many minutes before the prayer time
  /// the notification fires.
  static const String minutesBefore = 'prayer_notifications_minutes_before';

  /// "Play Adhan" (sound) toggle switch.
  static const String soundToggle = 'prayer_notifications_sound_toggle';
}
