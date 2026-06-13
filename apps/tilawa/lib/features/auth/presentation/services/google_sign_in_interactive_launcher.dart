import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';

/// Result of a pre-flight check before launching Google sign-in UI.
sealed class GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchReadiness();

  const factory GoogleSignInLaunchReadiness.ready() = GoogleSignInLaunchReady;

  const factory GoogleSignInLaunchReadiness.uiUnavailable() =
      GoogleSignInLaunchUiUnavailable;

  const factory GoogleSignInLaunchReadiness.platformError(
    PlatformException exception,
  ) = GoogleSignInLaunchPlatformError;
}

final class GoogleSignInLaunchReady extends GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchReady();
}

final class GoogleSignInLaunchUiUnavailable
    extends GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchUiUnavailable();
}

final class GoogleSignInLaunchPlatformError
    extends GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchPlatformError(this.exception);
  final PlatformException exception;
}

/// Frame / delay policy for deferring sign-in on heavy OEM cold starts.
abstract final class SignInUiSettleTiming {
  static const Duration defaultUiSettleDelay = Duration(milliseconds: 50);

  /// Extra time for Transsion/XOS after heavy cold-start frames (~135 skipped).
  static const Duration transsionUiSettleDelay = Duration(milliseconds: 450);

  static const int framesToWait = 2;

  static Duration settleDelay({required bool skipAutomaticSignIn}) {
    return skipAutomaticSignIn ? transsionUiSettleDelay : defaultUiSettleDelay;
  }

  static Future<void> waitForUiToSettle({required bool skipAutomaticSignIn}) {
    return _waitForFrames(SignInUiSettleTiming.framesToWait).then(
      (_) => Future<void>.delayed(
        settleDelay(skipAutomaticSignIn: skipAutomaticSignIn),
      ),
    );
  }

  static Future<void> _waitForFrames(int count) async {
    for (var i = 0; i < count; i++) {
      await _nextFrame();
    }
  }

  static Future<void> _nextFrame() {
    final Completer<void> completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }
}

/// Defers interactive Google sign-in until after the frame pipeline and OEM
/// window managers (e.g. Transsion HubCore) have settled.
@lazySingleton
class GoogleSignInInteractiveLauncher {
  GoogleSignInInteractiveLauncher(
    this._googleSignIn,
    this._platformPolicy,
  );

  final GoogleSignIn _googleSignIn;
  final AndroidSignInPlatformPolicy _platformPolicy;

  /// Whether Credential Manager / [GoogleSignIn.authenticate] can run on device.
  Future<GoogleSignInLaunchReadiness> checkReadiness() async {
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        logger.w('[GoogleSignIn] supportsAuthenticate() returned false');
        return const GoogleSignInLaunchReadiness.uiUnavailable();
      }
      return const GoogleSignInLaunchReadiness.ready();
    } on PlatformException catch (error, stackTrace) {
      logger.w(
        '[GoogleSignIn] supportsAuthenticate PlatformException: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
      return GoogleSignInLaunchReadiness.platformError(error);
    } catch (error, stackTrace) {
      logger.w(
        '[GoogleSignIn] supportsAuthenticate failed',
        error: error,
        stackTrace: stackTrace,
      );
      return GoogleSignInLaunchReadiness.platformError(
        PlatformException(code: 'unknown', message: error.toString()),
      );
    }
  }

  /// Runs [action] after microtask + settled frames + OEM-specific delay.
  Future<void> runAfterUiSettled(Future<void> Function() action) async {
    logger.d(
      '[GoogleSignIn] UI settle starting '
      '(transsion=${_platformPolicy.skipAutomaticSignIn})',
    );
    await Future<void>.delayed(Duration.zero);
    await SignInUiSettleTiming.waitForUiToSettle(
      skipAutomaticSignIn: _platformPolicy.skipAutomaticSignIn,
    );
    logger.d('[GoogleSignIn] UI settle complete → launching sign-in');
    await action();
  }
}
