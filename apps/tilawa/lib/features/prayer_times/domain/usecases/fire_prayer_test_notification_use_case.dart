import 'package:injectable/injectable.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';

/// Fires a one-off adhan notification for debug / QA flows.
@injectable
class FirePrayerTestNotificationUseCase {
  const FirePrayerTestNotificationUseCase(this._notificationService);

  final IPrayerAdhanNotificationService _notificationService;

  Future<void> call({
    required PrayerType prayer,
    required bool playAdhan,
  }) => _notificationService.fireTestNotification(
    prayer: prayer,
    playAdhan: playAdhan,
  );
}
