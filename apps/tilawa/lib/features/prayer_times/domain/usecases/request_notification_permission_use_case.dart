import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../../../../core/services/notification_permission_service.dart';

/// Requests the Android 13+ notification runtime permission.
///
/// Kept behind a use case so presentation never talks to platform permission
/// APIs directly.
@injectable
class RequestNotificationPermissionUseCase {
  const RequestNotificationPermissionUseCase(this._permissions);

  final NotificationPermissionService _permissions;

  Future<Either<Failure, bool>> call() async {
    try {
      final bool granted = await _permissions.requestPermission();
      return Right(granted);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
