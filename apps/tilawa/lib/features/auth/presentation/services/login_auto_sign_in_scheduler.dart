import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tilawa/core/logging/app_logger.dart';

/// Guards and schedules one-shot Google auto sign-in after OEM policy warm-up.
class LoginAutoSignInScheduler {
  bool _scheduled = false;
  bool _warmUpInFlight = false;

  /// Whether auto sign-in has already been scheduled for this screen instance.
  bool get isScheduled => _scheduled;

  /// Starts policy warm-up once, then posts auto sign-in when the route is ready.
  void scheduleWhenReady({
    required Future<void> Function() warmUpPolicy,
    required bool Function() shouldSkipAutoSignIn,
    required bool Function() isMounted,
    required bool Function() isRouteCurrent,
    required AppLifecycleState? Function() lifecycleState,
    required VoidCallback onAutoSignIn,
    void Function(String message)? log,
  }) {
    final void Function(String message) writeLog =
        log ?? (String message) => logger.d('[GoogleSignInButton] $message');

    if (_scheduled) {
      writeLog('scheduleAutoSignIn skipped: already scheduled');
      return;
    }
    if (_warmUpInFlight) {
      writeLog('scheduleAutoSignIn skipped: warm-up already in flight');
      return;
    }

    _warmUpInFlight = true;
    unawaited(
      warmUpPolicy()
          .then((_) {
            _warmUpInFlight = false;
            if (!isMounted()) {
              return;
            }
            _scheduleAfterWarmUp(
              shouldSkipAutoSignIn: shouldSkipAutoSignIn,
              isMounted: isMounted,
              isRouteCurrent: isRouteCurrent,
              lifecycleState: lifecycleState,
              onAutoSignIn: onAutoSignIn,
              log: writeLog,
            );
          })
          .catchError((Object error, StackTrace stackTrace) {
            _warmUpInFlight = false;
            logger.w(
              '[GoogleSignInButton] sign-in policy warm-up failed',
              error: error,
              stackTrace: stackTrace,
            );
          }),
    );
  }

  void _scheduleAfterWarmUp({
    required bool Function() shouldSkipAutoSignIn,
    required bool Function() isMounted,
    required bool Function() isRouteCurrent,
    required AppLifecycleState? Function() lifecycleState,
    required VoidCallback onAutoSignIn,
    required void Function(String message) log,
  }) {
    if (shouldSkipAutoSignIn()) {
      log(
        'scheduleAutoSignIn skipped: Transsion OEM (manual sign-in only)',
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted()) {
        log('scheduleAutoSignIn postFrame skipped: unmounted');
        return;
      }
      if (!isRouteCurrent()) {
        log(
          'scheduleAutoSignIn postFrame skipped: route not current '
          '(routeCurrent=false lifecycle=${lifecycleState()})',
        );
        return;
      }
      final AppLifecycleState? lifecycle = lifecycleState();
      if (lifecycle != AppLifecycleState.resumed) {
        log('scheduleAutoSignIn postFrame skipped: lifecycle=$lifecycle');
        return;
      }
      _scheduled = true;
      log(
        'scheduleAutoSignIn firing auto sign-in '
        '(routeCurrent=true lifecycle=$lifecycle)',
      );
      onAutoSignIn();
    });
  }
}
