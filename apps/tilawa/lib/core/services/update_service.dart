import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@singleton
class UpdateService {
  final Logger _logger = Logger();

  /// Checks for an update and performs it if available.
  ///
  /// [context] is required to show snackbars or dialogs if needed (though in_app_update handles most UI).
  Future<void> checkForUpdate() async {
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
            '[UpdateService] Flexible update available. Performing update.',
          );
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
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
}
