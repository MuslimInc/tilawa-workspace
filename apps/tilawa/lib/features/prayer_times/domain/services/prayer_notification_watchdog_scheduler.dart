/// Platform bridge that registers or triggers the native watchdog.
abstract interface class PrayerNotificationWatchdogScheduler {
  Future<void> ensurePeriodicWatchdogScheduled();

  Future<void> runWatchdogNow();
}
