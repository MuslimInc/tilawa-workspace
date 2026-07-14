import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

import '../entities/auth_error_key.dart';
import '../entities/device_info_snapshot.dart';
import '../entities/session_registration.dart';
import '../repositories/active_device_repository.dart';
import '../services/device_info_service.dart';
import '../services/token_sync_cache.dart';

@injectable
class RegisterActiveDeviceUseCase {
  RegisterActiveDeviceUseCase(
    this._repository,
    this._deviceTokenService,
    this._tokenSyncCache,
    this._appInfoService,
    this._deviceInfoService,
  );

  final ActiveDeviceRepository _repository;
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
    final List<Object?> parallel = await Future.wait<Object?>(
      <Future<Object?>>[
        _deviceTokenService.getToken(),
        _appInfoService.getAppInfo(),
        _deviceInfoService.getDeviceInfo(),
      ],
    );
    final String? token = parallel[0] as String?;
    final AppInfo appInfo = parallel[1]! as AppInfo;
    final DeviceInfoSnapshot deviceInfo = parallel[2]! as DeviceInfoSnapshot;

    final result = await _repository.registerActiveDevice(
      fcmToken: token,
      registrationMode: registrationMode,
      appVersion: appInfo.version,
      deviceInfo: deviceInfo,
    );

    final Failure? registerFailure = result.fold(
      (failure) => failure,
      (_) => null,
    );
    if (registerFailure != null) {
      return Left(registerFailure);
    }
    final registration = result.getOrElse(
      () => throw StateError('expected registration'),
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
  }

  Future<Either<Failure, void>> clearActiveDeviceOnSignOut(
    String userId,
  ) async {
    try {
      await _repository.registerActiveDevice(
        fcmToken: '',
        registrationMode: DeviceRegistrationMode.passiveSync,
        signOut: true,
      );
    } catch (_) {
      // Best-effort: still clear local session below.
    }
    await _tokenSyncCache.clearSession();
    return const Right(null);
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
