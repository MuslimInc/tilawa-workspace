import '../entities/prayer_notification_schedule_snapshot.dart';

/// Stores lightweight metadata about the currently scheduled prayer window.
abstract interface class PrayerNotificationScheduleRepository {
  Future<PrayerNotificationScheduleSnapshot?> loadSnapshot();

  Future<void> saveSnapshot(PrayerNotificationScheduleSnapshot snapshot);

  Future<void> clearSnapshot();
}
