import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/device_info_snapshot.dart';
import '../entities/session_registration.dart';

/// Registers / clears the active-device session via backend callable.
abstract class ActiveDeviceRepository {
  Future<Either<Failure, SessionRegistration>> registerActiveDevice({
    required DeviceRegistrationMode registrationMode,
    String? fcmToken,
    String? appVersion,
    DeviceInfoSnapshot? deviceInfo,
    bool signOut = false,
  });

  /// Stable per-install device id (same source used during registration).
  Future<String> currentDeviceId();
}
