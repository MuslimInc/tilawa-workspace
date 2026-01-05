import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/device_token_service.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/domain/usecases/sync_device_token_use_case.dart';

@lazySingleton
class FCMService {
  FCMService(
    this._authService,
    this._syncDeviceTokenUseCase,
    this._deviceTokenService,
  );

  final AuthService _authService;
  final SyncDeviceTokenUseCase _syncDeviceTokenUseCase;
  final DeviceTokenService _deviceTokenService;

  StreamSubscription? _authSubscription;
  StreamSubscription? _tokenSubscription;

  void initialize() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await _syncDeviceTokenUseCase(user.uid);
      }
    });

    _tokenSubscription = _deviceTokenService.onTokenRefresh.listen((
      token,
    ) async {
      final User? user = _authService.currentUser;
      if (user != null) {
        // SyncDeviceTokenUseCase fetches the token internally or we can specificy if modified.
        // The existing SyncDeviceTokenUseCase fetches via DeviceTokenService.getToken().
        // When onTokenRefresh fires, getToken() should be up to date.
        await _syncDeviceTokenUseCase(user.uid);
      }
    });
  }

  void dispose() {
    _authSubscription?.cancel();
    _tokenSubscription?.cancel();
  }
}
