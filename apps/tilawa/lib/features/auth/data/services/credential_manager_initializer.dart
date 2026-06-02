import 'package:credential_manager/credential_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/core/auth_config.dart';
import 'package:tilawa_core/constants/app_strings.dart';

/// Ensures [CredentialManager] is initialized before sign-in on Android.
@lazySingleton
class CredentialManagerInitializer {
  CredentialManagerInitializer(this._credentialManager);

  final CredentialManager _credentialManager;

  Future<void>? _initFuture;

  Future<void> ensureReady() {
    if (!AuthConfig.useCredentialManager) {
      return Future<void>.value();
    }
    return _initFuture ??= _runInit();
  }

  Future<void> _runInit() async {
    try {
      await _credentialManager.init(
        preferImmediatelyAvailableCredentials: true,
        googleClientId: AppStrings.googleClientId,
      );
    } catch (_) {
      // Sign-in may still succeed; init is best-effort.
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _initFuture = null;
  }
}
