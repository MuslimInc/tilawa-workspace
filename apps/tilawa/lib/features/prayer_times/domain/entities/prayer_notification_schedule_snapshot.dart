/// Persisted view of the prayer notification schedule window.
///
/// This intentionally stores metadata about the schedule rather than the full
/// notification payload list. The actual AlarmManager/flutter_local_notifications
/// entries remain owned by the scheduler implementations.
class PrayerNotificationScheduleSnapshot {
  const PrayerNotificationScheduleSnapshot({
    required this.scheduledUntil,
    required this.scheduledAt,
    required this.scheduledCount,
    this.scheduledFrom,
  });

  final DateTime? scheduledFrom;
  final DateTime scheduledUntil;
  final DateTime scheduledAt;
  final int scheduledCount;

  Duration remainingWindow(DateTime now) => scheduledUntil.difference(now);
}
