import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/device_token_service.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/usecases/sync_device_token_use_case.dart';

@lazySingleton
class FCMService {
  FCMService(
    this._authRepository,
    this._syncDeviceTokenUseCase,
    this._deviceTokenService,
  );

  final AuthRepository _authRepository;
  final SyncDeviceTokenUseCase _syncDeviceTokenUseCase;
  final DeviceTokenService _deviceTokenService;

  StreamSubscription? _authSubscription;
  StreamSubscription? _tokenRefreshSubscription;

  void initialize() {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      _syncDeviceTokenUseCase(currentUser.id);
    }

    _authSubscription = _authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        await _syncDeviceTokenUseCase(user.id);
      }
    });

    _tokenRefreshSubscription = _deviceTokenService.onTokenRefresh.listen((token) async {
      final user = _authRepository.currentUser;
      if (user != null) {
        await _syncDeviceTokenUseCase(user.id);
      }
    });
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }
}
