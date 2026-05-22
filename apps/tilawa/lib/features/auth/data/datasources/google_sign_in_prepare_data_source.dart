import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/core/auth_config.dart';
import 'package:tilawa_core/constants/app_strings.dart';

/// Prepares the platform Google sign-in UI before the login screen is shown.
abstract class GoogleSignInPrepareDataSource {
  Future<void> prepare();

  Future<void> clear();
}

@LazySingleton(as: GoogleSignInPrepareDataSource)
class GoogleSignInPrepareDataSourceImpl implements GoogleSignInPrepareDataSource {
  /// Production constructor — only [googleSignIn] is resolved by injectable.
  GoogleSignInPrepareDataSourceImpl(this._googleSignIn)
      : _useAndroidCredentialManager = null,
        _useGoogleSignInPath = null;

  /// Test-only overrides for platform branches (not registered in GetIt).
  @visibleForTesting
  GoogleSignInPrepareDataSourceImpl.withOptions(
    this._googleSignIn, {
    bool? useAndroidCredentialManager,
    bool? useGoogleSignInPath,
  }) : _useAndroidCredentialManager = useAndroidCredentialManager,
       _useGoogleSignInPath = useGoogleSignInPath;

  @visibleForTesting
  static void resetPrepareStateForTesting() {
    _prepareDone = false;
    _prepareInFlight = null;
  }

  static const MethodChannel _channel = MethodChannel(
    'com.tilawa.app/google_sign_in_prepare',
  );

  static bool _prepareDone = false;
  static Future<void>? _prepareInFlight;

  final GoogleSignIn _googleSignIn;
  final bool? _useAndroidCredentialManager;
  final bool? _useGoogleSignInPath;

  bool get _shouldUseAndroidCredentialManager =>
      _useAndroidCredentialManager ??
      (AuthConfig.useCredentialManager && Platform.isAndroid);

  bool get _shouldUseGoogleSignIn =>
      _useGoogleSignInPath ?? AuthConfig.useGoogleSignIn;

  @override
  Future<void> prepare() async {
    if (_prepareDone) {
      return;
    }
    if (_prepareInFlight != null) {
      await _prepareInFlight;
      return;
    }

    final Future<void> run = _runPrepare();
    _prepareInFlight = run;
    try {
      await run;
      _prepareDone = true;
    } finally {
      _prepareInFlight = null;
    }
  }

  Future<void> _runPrepare() async {
    try {
      if (_shouldUseAndroidCredentialManager) {
        await _channel.invokeMethod<bool>(
          'prepare',
          <String, String>{'google_client_id': AppStrings.googleClientId},
        );
        return;
      }
      if (_shouldUseGoogleSignIn) {
        await _googleSignIn.initialize(
          serverClientId: AppStrings.googleClientId,
        );
        await _googleSignIn.attemptLightweightAuthentication();
        return;
      }
    } catch (_) {
      // Best-effort warmup; sign-in still works without prepare.
    }
  }

  @override
  Future<void> clear() async {
    _prepareDone = false;
    _prepareInFlight = null;
    try {
      if (_shouldUseAndroidCredentialManager) {
        await _channel.invokeMethod<void>('clear');
      }
    } catch (_) {
      // Best-effort cache reset.
    }
  }
}
