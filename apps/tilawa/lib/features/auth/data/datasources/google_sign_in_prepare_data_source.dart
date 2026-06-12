import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa_core/constants/app_strings.dart';

/// Prepares Google sign-in before the login screen is shown.
///
/// This deliberately shows no UI: it only initializes the plugin and warms
/// the OEM policy. The interactive flows (lightweight bottom sheet first,
/// button-flow dialog as fallback) are owned by GoogleAuthProviderImpl.
abstract class GoogleSignInPrepareDataSource {
  /// Runs [GoogleSignIn.initialize] exactly once per process.
  ///
  /// google_sign_in 7.x requires initialize() before any other method and
  /// forbids calling it twice (undefined behavior), so the cached future is
  /// only dropped after a failure, to allow a retry.
  Future<void> ensureInitialized();

  /// Best-effort warm-up of the OEM policy and sign-in initialization.
  Future<void> prepare();
}

@LazySingleton(as: GoogleSignInPrepareDataSource)
class GoogleSignInPrepareDataSourceImpl
    implements GoogleSignInPrepareDataSource {
  GoogleSignInPrepareDataSourceImpl(
    this._googleSignIn,
    this._platformPolicy,
  );

  @visibleForTesting
  static void resetPrepareStateForTesting() {
    _initFuture = null;
  }

  static Future<void>? _initFuture;

  final GoogleSignIn _googleSignIn;
  final AndroidSignInPlatformPolicy _platformPolicy;

  @override
  Future<void> ensureInitialized() {
    final Future<void>? pending = _initFuture;
    if (pending != null) {
      return pending;
    }
    final Future<void> run = _runInitialize();
    _initFuture = run;
    // On failure, drop the cached future so the next call retries; the
    // caller still observes the error through [run].
    unawaited(
      run.then<void>(
        (_) {},
        onError: (Object _) {
          _initFuture = null;
        },
      ),
    );
    return run;
  }

  Future<void> _runInitialize() async {
    await _googleSignIn.initialize(
      clientId: Platform.isIOS ? AppStrings.googleIosClientId : null,
      serverClientId: AppStrings.googleClientId,
    );
  }

  @override
  Future<void> prepare() async {
    await _platformPolicy.warmUp();
    try {
      await ensureInitialized();
    } catch (_) {
      // Best-effort warmup; sign-in surfaces its own initialization error.
    }
  }
}
