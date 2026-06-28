import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

import '../../data/datasources/active_device_remote_data_source.dart';
import '../../data/services/device_identity_service.dart';
import '../entities/auth_error_key.dart';
import '../entities/session_registration.dart';
import '../services/device_info_service.dart';
import '../services/token_sync_cache.dart';

@injectable
class RegisterActiveDeviceUseCase {
  RegisterActiveDeviceUseCase(
    this._remoteDataSource,
    this._deviceIdentityService,
    this._deviceTokenService,
    this._tokenSyncCache,
    this._appInfoService,
    this._deviceInfoService,
  );

  final ActiveDeviceRemoteDataSource _remoteDataSource;
  final DeviceIdentityService _deviceIdentityService;
  final DeviceTokenService _deviceTokenService;
  final TokenSyncCache _tokenSyncCache;
  final AppInfoService _appInfoService;
  final DeviceInfoService _deviceInfoService;

  Future<Either<Failure, SessionRegistration>> registerExplicitSignIn(
    String userId,
  ) {
    return _register(
      userId,
      registrationMode: DeviceRegistrationMode.explicitSignIn,
    );
  }

  Future<Either<Failure, SessionRegistration>> syncPassive(String userId) {
    return _register(
      userId,
      registrationMode: DeviceRegistrationMode.passiveSync,
    );
  }

  Future<Either<Failure, SessionRegistration>> _register(
    String userId, {
    required DeviceRegistrationMode registrationMode,
  }) async {
    try {
      final String? token = await _deviceTokenService.getToken();
      final deviceId = await _deviceIdentityService.getDeviceId();
      final appInfo = await _appInfoService.getAppInfo();
      final deviceInfo = await _deviceInfoService.getDeviceInfo();

      final registration = await _remoteDataSource.registerActiveDevice(
        deviceId: deviceId,
        fcmToken: token,
        registrationMode: registrationMode,
        platform: _deviceIdentityService.platform,
        appVersion: appInfo.version,
        deviceInfo: deviceInfo,
      );

      if (!registration.isActiveDevice) {
        await _tokenSyncCache.clearSession();
        return Left(_registrationFailure(registration.status));
      }

      if (token != null && token.isNotEmpty) {
        await _tokenSyncCache.saveSync(token, userId);
      }
      await _tokenSyncCache.saveSessionEpoch(registration.epoch);
      final activeDeviceId = registration.activeDeviceId;
      if (activeDeviceId != null && activeDeviceId.isNotEmpty) {
        await _tokenSyncCache.saveActiveDeviceId(activeDeviceId);
      }

      return Right(registration);
    } on FirebaseFunctionsException catch (error) {
      return Left(
        Failure.serverError(
          error.message ?? AuthErrorKey.deviceRegistrationFailed,
        ),
      );
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  Future<Either<Failure, void>> clearActiveDeviceOnSignOut(
    String userId,
  ) async {
    try {
      final deviceId =
          await _tokenSyncCache.getActiveDeviceId() ??
          await _deviceIdentityService.getDeviceId();

      await _remoteDataSource.registerActiveDevice(
        deviceId: deviceId,
        fcmToken: '',
        registrationMode: DeviceRegistrationMode.passiveSync,
        platform: _deviceIdentityService.platform,
        signOut: true,
      );
      await _tokenSyncCache.clearSession();
      return const Right(null);
    } catch (_) {
      await _tokenSyncCache.clearSession();
      return const Right(null);
    }
  }

  Failure _registrationFailure(SessionRegistrationStatus status) {
    return switch (status) {
      SessionRegistrationStatus.staleDeviceRejected => const PermissionFailure(
        AuthErrorKey.staleDeviceRejected,
      ),
      SessionRegistrationStatus.requiresExplicitSignIn =>
        const PermissionFailure(AuthErrorKey.requiresExplicitSignIn),
      _ => const ServerFailure(AuthErrorKey.deviceRegistrationFailed),
    };
  }
}
