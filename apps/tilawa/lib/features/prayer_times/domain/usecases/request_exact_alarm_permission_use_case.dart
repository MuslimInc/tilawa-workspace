import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../services/prayer_adhan_notification_service_interface.dart';

/// Opens the system settings for the Android 12+ exact-alarm permission.
///
/// No-op on platforms where the permission does not exist; failures are
/// surfaced as a [Failure] so the UI can render an explanation.
@injectable
class RequestExactAlarmPermissionUseCase {
  const RequestExactAlarmPermissionUseCase(this._service);

  final IPrayerAdhanNotificationService _service;

  Future<Either<Failure, void>> call() async {
    try {
      await _service.requestExactAlarmPermission();
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
