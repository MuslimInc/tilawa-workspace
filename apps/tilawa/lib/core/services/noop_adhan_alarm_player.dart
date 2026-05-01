import '../../features/prayer_times/domain/services/adhan_alarm_player_interface.dart';

/// No-op [IAdhanAlarmPlayer] kept for tests and for non-Android platforms
/// (e.g. iOS, where this app is not currently shipped — the production
/// binding is [AndroidAdhanAlarmPlayer]).
class NoOpAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  const NoOpAdhanAlarmPlayer();

  @override
  bool get isSupported => false;

  @override
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
  }) async => false;

  @override
  Future<void> cancelAdhan(int id) async {}

  @override
  Future<void> cancelAllAdhans() async {}

  @override
  Future<void> persistPendingAlarms(List<PendingAdhanAlarm> alarms) async {}

  @override
  Future<bool> consumeNeedsRescheduleAfterBoot() async => false;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}

  @override
  Future<String?> manufacturer() async => null;
}
