import '../../features/prayer_times/domain/services/adhan_alarm_player_interface.dart';

/// No-op [IAdhanAlarmPlayer] kept for tests and for non-Android platforms
/// (e.g. iOS, where this app is not currently shipped — the production
/// binding is [AndroidAdhanAlarmPlayer]).
class NoOpAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  const NoOpAdhanAlarmPlayer();

  @override
  bool get isSupported => false;

  @override
  Stream<String> get onNotificationTapped => const Stream.empty();

  @override
  Future<void> flushPendingNotificationTap() async {}

  @override
  Future<String?> pullPendingNotificationTapPayload() async => null;

  @override
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerKey,
    String? sound,
  }) async => false;

  @override
  Future<bool> playAdhanNow({
    required int id,
    required String prayerName,
    required String prayerKey,
    String? sound,
  }) async => false;

  @override
  Future<void> cancelAdhan(int id, {String? prayerName}) async {}

  @override
  Future<void> cancelAllAdhans() async {}

  @override
  Future<void> persistPendingAlarms(List<PendingAdhanAlarm> alarms) async {}

  @override
  Future<bool> consumeNeedsRescheduleAfterBoot() async => false;

  @override
  Future<void> markNeedsReschedule() async {}

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}

  @override
  Future<String?> manufacturer() async => null;

  @override
  Future<void> stopCurrentAdhan() async {}

  @override
  Future<bool> isAdhanPlaying() async => false;

  @override
  Future<String?> getActiveAdhanPayload() async => null;
}
