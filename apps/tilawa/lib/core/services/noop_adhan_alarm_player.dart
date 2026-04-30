import 'package:injectable/injectable.dart';

import '../../features/prayer_times/domain/services/adhan_alarm_player_interface.dart';

/// Phase 1 [IAdhanAlarmPlayer] implementation — does nothing.
///
/// The Phase 1 prayer notification feature relies entirely on the system
/// notification sound (no bundled adhan asset is shipped yet). This implementation
/// preserves the abstraction so Phase 2 can swap in an audio-backed player
/// without touching domain, BLoC, or UI code.
@LazySingleton(as: IAdhanAlarmPlayer)
class NoOpAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  const NoOpAdhanAlarmPlayer();

  @override
  bool get isSupported => false;

  @override
  Future<void> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
  }) async {}

  @override
  Future<void> cancelAdhan(int id) async {}

  @override
  Future<void> cancelAllAdhans() async {}
}
