import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../services/prayer_adhan_notification_service_interface.dart';

/// Cancels every scheduled prayer notification.
@injectable
class CancelPrayerNotificationsUseCase {
  const CancelPrayerNotificationsUseCase(this._service);

  final IPrayerAdhanNotificationService _service;

  Future<Either<Failure, void>> call() async {
    try {
      await _service.cancelAllPrayerNotifications();
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
