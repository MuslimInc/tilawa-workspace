import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa/features/auth/domain/entities/google_sign_in_launch_readiness.dart';
import 'package:tilawa/features/auth/domain/gateways/google_sign_in_launch_gateway.dart';

export 'package:tilawa/features/auth/domain/entities/google_sign_in_launch_readiness.dart';

/// Frame / delay policy for deferring sign-in on heavy OEM cold starts.
abstract final class SignInUiSettleTiming {
  static const Duration defaultUiSettleDelay = Duration(milliseconds: 50);

  /// Extra time for Transsion/XOS after heavy cold-start frames (~135 skipped).
  static const Duration transsionUiSettleDelay = Duration(milliseconds: 450);

  static const int framesToWait = 2;

  /// Test override for frame/timer settle; production uses real frames.
  @visibleForTesting
  static Future<void> Function({required bool skipAutomaticSignIn})?
  debugWaitForUiToSettle;

  static Duration settleDelay({required bool skipAutomaticSignIn}) {
    return skipAutomaticSignIn ? transsionUiSettleDelay : defaultUiSettleDelay;
  }

  static Future<void> waitForUiToSettle({required bool skipAutomaticSignIn}) {
    final Future<void> Function({required bool skipAutomaticSignIn})? override =
        debugWaitForUiToSettle;
    if (override != null) {
      return override(skipAutomaticSignIn: skipAutomaticSignIn);
    }
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
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      SchedulerBinding.instance.scheduleFrame();
    }
    return completer.future;
  }
}

/// Defers interactive Google sign-in until after the frame pipeline and OEM
/// window managers (e.g. Transsion HubCore) have settled.
@LazySingleton(as: GoogleSignInLaunchGateway)
class GoogleSignInInteractiveLauncher implements GoogleSignInLaunchGateway {
  GoogleSignInInteractiveLauncher(
    this._googleSignIn,
    this._platformPolicy,
  );

  final GoogleSignIn _googleSignIn;
  final AndroidSignInPlatformPolicy _platformPolicy;

  /// Whether Credential Manager / [GoogleSignIn.authenticate] can run on device.
  @override
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
      return GoogleSignInLaunchReadiness.platformError(
        code: error.code,
        message: error.message,
      );
    } catch (error, stackTrace) {
      logger.w(
        '[GoogleSignIn] supportsAuthenticate failed',
        error: error,
        stackTrace: stackTrace,
      );
      return GoogleSignInLaunchReadiness.platformError(
        code: 'unknown',
        message: error.toString(),
      );
    }
  }

  /// Runs [action] after microtask + settled frames + OEM-specific delay.
  @override
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
