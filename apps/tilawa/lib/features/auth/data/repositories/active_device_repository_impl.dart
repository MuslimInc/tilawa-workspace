import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/firebase/app_check_failure.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/auth_error_key.dart';
import '../../domain/entities/device_info_snapshot.dart';
import '../../domain/entities/session_registration.dart';
import '../../domain/repositories/active_device_repository.dart';
import '../datasources/active_device_remote_data_source.dart';
import '../services/device_identity_service.dart';

@LazySingleton(as: ActiveDeviceRepository)
class ActiveDeviceRepositoryImpl implements ActiveDeviceRepository {
  ActiveDeviceRepositoryImpl(this._remoteDataSource, this._deviceIdentity);

  final ActiveDeviceRemoteDataSource _remoteDataSource;
  final DeviceIdentityService _deviceIdentity;

  @override
  Future<String> currentDeviceId() => _deviceIdentity.getDeviceId();

  @override
  Future<Either<Failure, SessionRegistration>> registerActiveDevice({
    required DeviceRegistrationMode registrationMode,
    String? fcmToken,
    String? appVersion,
    DeviceInfoSnapshot? deviceInfo,
    bool signOut = false,
  }) async {
    try {
      final deviceId = await _deviceIdentity.getDeviceId();
      final registration = await _remoteDataSource.registerActiveDevice(
        deviceId: deviceId,
        fcmToken: fcmToken,
        registrationMode: registrationMode,
        platform: _deviceIdentity.platform,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
        signOut: signOut,
      );
      return Right(registration);
    } on FirebaseFunctionsException catch (error) {
      final String message = isAppCheckCallableFailureFromException(error)
          ? AuthErrorKey.appCheckFailed
          : (error.message ?? AuthErrorKey.deviceRegistrationFailed);
      return Left(Failure.serverError(message));
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }
}
