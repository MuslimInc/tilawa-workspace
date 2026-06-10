import '../entities/tasbeeh_dhikr.dart';

/// Schedules and cancels per-dhikr daily local notifications.
abstract class TasbeehReminderScheduler {
  Future<void> scheduleReminder(TasbeehDhikr dhikr);

  Future<void> cancelReminder(String dhikrId);

  Future<void> cancelReminders(Iterable<String> dhikrIds);

  Future<void> ensureAllScheduled(Iterable<TasbeehDhikr> dhikr);
}
