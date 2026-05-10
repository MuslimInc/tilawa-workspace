import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:tilawa/router/app_router.dart';

@singleton
class UpdateService {
  final Logger _logger = Logger();

  /// Minimum interval between update checks to avoid interrupting the user
  /// on every app resume.
  static const Duration _minCheckInterval = Duration(hours: 6);
  static DateTime? _lastCheckTime;
  static Future<void>? _inFlightCheck;

  /// Checks for an update and performs it if available.
  ///
  /// Throttled to at most once per [_minCheckInterval] to avoid repeatedly
  /// prompting the user with an immediate update dialog on every resume.
  Future<void> checkForUpdate() async {
    if (_inFlightCheck != null) {
      await _inFlightCheck;
      return;
    }

    final Future<void> checkFuture = _checkForUpdateInternal();
    _inFlightCheck = checkFuture;
    try {
      await checkFuture;
    } finally {
      if (identical(_inFlightCheck, checkFuture)) {
        _inFlightCheck = null;
      }
    }
  }

  Future<void> _checkForUpdateInternal() async {
    final DateTime now = DateTime.now();
    if (_lastCheckTime != null &&
        now.difference(_lastCheckTime!) < _minCheckInterval) {
      return;
    }
    _lastCheckTime = now;
    if (!Platform.isAndroid) {
      _logger.i(
        '[UpdateService] In-app updates are only supported on Android.',
      );
      return;
    }

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          _logger.i(
            '[UpdateService] Immediate update available. Performing update.',
          );
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          _logger.i(
            '[UpdateService] Flexible update available. Starting download.',
          );
          final AppUpdateResult result =
              await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            _logger.i(
              '[UpdateService] Flexible update downloaded; prompting user.',
            );
            _offerFlexibleUpdateRestart();
          } else {
            _logger.w('[UpdateService] Flexible update result: $result');
          }
        }
      } else {
        _logger.i('[UpdateService] No update available.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'TASK_FAILURE' &&
          (e.message?.contains('Install Error(-10)') ?? false)) {
        _logger.d(
          '[UpdateService] App not owned (Install Error -10). '
          'This is expected in debug mode or if not installed from Play Store.',
        );
      } else {
        _logger.e('[UpdateService] Failed to check for update: $e');
      }
    } catch (e) {
      _logger.e('[UpdateService] Failed to check for update: $e');
    }
  }

  /// Lets the user finish a flexible update when convenient instead of
  /// restarting the app immediately.
  void _offerFlexibleUpdateRestart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? ctx = AppRouter.navigatorKey.currentContext;
      if (ctx == null) return;
      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(ctx);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(
            'Update downloaded. Restart when you are ready to install it.',
          ),
          action: SnackBarAction(
            label: 'Restart',
            onPressed: () {
              InAppUpdate.completeFlexibleUpdate();
            },
          ),
          duration: const Duration(minutes: 5),
        ),
      );
    });
  }
}
