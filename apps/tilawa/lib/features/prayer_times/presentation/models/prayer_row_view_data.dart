import '../../domain/entities/prayer_time_entity.dart';

/// Dense alert state used by Prayer Times presentation widgets.
enum PrayerAlertViewState {
  /// No notification or Adhan is scheduled.
  off,

  /// A notification is scheduled without Adhan playback.
  notification,

  /// A notification is scheduled with Adhan playback.
  adhan,
}

/// Presentation data for one prayer's alert state.
class PrayerAlertViewData {
  const PrayerAlertViewData({
    required this.state,
    required this.label,
    required this.supportsAlerts,
    required this.supportsAdhan,
  });

  final PrayerAlertViewState state;
  final String label;
  final bool supportsAlerts;
  final bool supportsAdhan;
}

/// Presentation model for rendering one prayer row in today's list.
class PrayerRowViewData {
  const PrayerRowViewData({
    required this.type,
    required this.prayerName,
    required this.prayerTime,
    required this.statusText,
    required this.isCurrent,
    required this.hasPassed,
    required this.isSecondary,
    required this.showAlertIndicators,
    required this.notificationEnabled,
    required this.adhanEnabled,
    required this.alert,
  });

  final PrayerType type;
  final String prayerName;
  final String prayerTime;
  final String statusText;
  final bool isCurrent;
  final bool hasPassed;

  /// Secondary rows are intentionally lower emphasis (for example Sunrise).
  final bool isSecondary;

  /// Whether the row supports notification/adhan status badges.
  final bool showAlertIndicators;

  final bool notificationEnabled;
  final bool adhanEnabled;
  final PrayerAlertViewData alert;
}
