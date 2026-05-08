import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';

import '../../domain/entities/prayer_notification_schedule_snapshot.dart';
import '../../domain/repositories/prayer_notification_schedule_repository.dart';

@LazySingleton(as: PrayerNotificationScheduleRepository)
class PrayerNotificationScheduleRepositoryImpl
    implements PrayerNotificationScheduleRepository {
  const PrayerNotificationScheduleRepositoryImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<PrayerNotificationScheduleSnapshot?> loadSnapshot() async {
    final int? endMs = await _prefs.getInt(
      PrayerNotificationConfig.scheduledWindowEndMsKey,
    );
    final int? completedAtMs = await _prefs.getInt(
      PrayerNotificationConfig.scheduleCompletedAtMsKey,
    );
    if (endMs == null || completedAtMs == null) {
      return null;
    }

    final int? startMs = await _prefs.getInt(
      PrayerNotificationConfig.scheduledWindowStartMsKey,
    );
    final int count =
        await _prefs.getInt(
          PrayerNotificationConfig.scheduledNotificationCountKey,
        ) ??
        0;

    return PrayerNotificationScheduleSnapshot(
      scheduledFrom: startMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startMs),
      scheduledUntil: DateTime.fromMillisecondsSinceEpoch(endMs),
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(completedAtMs),
      scheduledCount: count,
    );
  }

  @override
  Future<void> saveSnapshot(PrayerNotificationScheduleSnapshot snapshot) async {
    final DateTime? from = snapshot.scheduledFrom;
    if (from == null) {
      await _prefs.remove(PrayerNotificationConfig.scheduledWindowStartMsKey);
    } else {
      await _prefs.setInt(
        PrayerNotificationConfig.scheduledWindowStartMsKey,
        from.millisecondsSinceEpoch,
      );
    }
    await _prefs.setInt(
      PrayerNotificationConfig.scheduledWindowEndMsKey,
      snapshot.scheduledUntil.millisecondsSinceEpoch,
    );
    await _prefs.setInt(
      PrayerNotificationConfig.scheduleCompletedAtMsKey,
      snapshot.scheduledAt.millisecondsSinceEpoch,
    );
    await _prefs.setInt(
      PrayerNotificationConfig.scheduledNotificationCountKey,
      snapshot.scheduledCount,
    );
  }

  @override
  Future<void> clearSnapshot() async {
    await _prefs.remove(PrayerNotificationConfig.scheduledWindowStartMsKey);
    await _prefs.remove(PrayerNotificationConfig.scheduledWindowEndMsKey);
    await _prefs.remove(PrayerNotificationConfig.scheduleCompletedAtMsKey);
    await _prefs.remove(PrayerNotificationConfig.scheduledNotificationCountKey);
  }
}
