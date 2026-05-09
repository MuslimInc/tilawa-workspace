import '../../domain/entities/prayer_time_entity.dart';

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
}
