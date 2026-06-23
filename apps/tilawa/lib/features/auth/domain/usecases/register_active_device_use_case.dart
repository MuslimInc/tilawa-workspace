import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

import '../../data/datasources/active_device_remote_data_source.dart';
import '../../data/services/device_identity_service.dart';
import '../../domain/entities/session_registration.dart';
import '../../domain/services/token_sync_cache.dart';

@injectable
class RegisterActiveDeviceUseCase {
  RegisterActiveDeviceUseCase(
    this._remoteDataSource,
    this._deviceIdentityService,
    this._deviceTokenService,
    this._tokenSyncCache,
    this._appInfoService,
  );

  final ActiveDeviceRemoteDataSource _remoteDataSource;
  final DeviceIdentityService _deviceIdentityService;
  final DeviceTokenService _deviceTokenService;
  final TokenSyncCache _tokenSyncCache;
  final AppInfoService _appInfoService;

  Future<Either<Failure, SessionRegistration>> call(String userId) async {
    try {
      final String? token = await _deviceTokenService.getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure.validationError('FCM token unavailable'));
      }

      final deviceId = await _deviceIdentityService.getDeviceId();
      final appInfo = await _appInfoService.getAppInfo();

      final registration = await _remoteDataSource.registerActiveDevice(
        deviceId: deviceId,
        fcmToken: token,
        platform: _deviceIdentityService.platform,
        appVersion: appInfo.version,
      );

      await _tokenSyncCache.saveSync(token, userId);
      await _tokenSyncCache.saveSessionEpoch(registration.epoch);
      await _tokenSyncCache.saveActiveDeviceId(registration.activeDeviceId);

      return Right(registration);
    } on FirebaseFunctionsException catch (error) {
      return Left(
        Failure.serverError(
          error.message ?? 'Failed to register active device',
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
}
