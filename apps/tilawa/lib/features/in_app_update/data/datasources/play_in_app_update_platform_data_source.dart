import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../domain/entities/in_app_update_availability.dart';
import 'in_app_update_platform_data_source.dart';

@LazySingleton(as: InAppUpdatePlatformDataSource)
class PlayInAppUpdatePlatformDataSource
    implements InAppUpdatePlatformDataSource {
  @override
  Future<bool> isSupported() async => Platform.isAndroid;

  @override
  Future<InAppUpdateAvailability> checkAvailability() async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      return InAppUpdateAvailability(
        updateAvailable:
            updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable,
        immediateUpdateAllowed: updateInfo.immediateUpdateAllowed,
        flexibleUpdateAllowed: updateInfo.flexibleUpdateAllowed,
      );
    } on PlatformException catch (e) {
      if (_isAppNotOwnedError(e)) {
        logger.d(
          '[InAppUpdatePlatform] App not owned (Install Error -10). '
          'Expected in debug or sideloaded builds.',
        );
      } else {
        logger.e('[InAppUpdatePlatform] checkAvailability failed: $e');
      }
      return const InAppUpdateAvailability.unavailable();
    } catch (e) {
      logger.e('[InAppUpdatePlatform] checkAvailability failed: $e');
      return const InAppUpdateAvailability.unavailable();
    }
  }

  @override
  Future<void> performImmediateUpdate() async {
    await InAppUpdate.performImmediateUpdate();
  }

  @override
  Future<bool> startFlexibleUpdate() async {
    try {
      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) {
        logger.w('[InAppUpdatePlatform] Flexible update result: $result');
        return false;
      }
      return true;
    } catch (e) {
      logger.e('[InAppUpdatePlatform] startFlexibleUpdate failed: $e');
      return false;
    }
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    await InAppUpdate.completeFlexibleUpdate();
  }

  bool _isAppNotOwnedError(PlatformException error) {
    return error.code == 'TASK_FAILURE' &&
        (error.message?.contains('Install Error(-10)') ?? false);
  }
}
