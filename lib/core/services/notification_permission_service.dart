import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:muzakri/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle notification permission requests
@lazySingleton
class NotificationPermissionService {
  static const String _notificationPermissionRequestedKey =
      'notification_permission_requested';
  static const String _isFirstLaunchKey = 'is_first_launch';

  final SharedPreferencesAsync _prefs;

  NotificationPermissionService(this._prefs);

  /// Check if this is the first time the app is launched
  Future<bool> isFirstLaunch() async {
    final isFirstLaunch = await _prefs.getBool(_isFirstLaunchKey) ?? true;
    if (isFirstLaunch) {
      // Mark that first launch has been checked
      await _prefs.setBool(_isFirstLaunchKey, false);
    }
    return isFirstLaunch;
  }

  /// Check if notification permission has already been requested
  Future<bool> hasRequestedPermission() async {
    return await _prefs.getBool(_notificationPermissionRequestedKey) ?? false;
  }

  /// Check if notification permission is granted
  Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) {
      // iOS doesn't require explicit notification permission request
      // The system will prompt automatically when needed
      return true;
    }

    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission (only on Android 13+)
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) {
      // iOS doesn't require explicit notification permission request
      logger.d('[NotificationPermissionService] iOS - permission not required');
      return true;
    }

    try {
      // Check if permission is already granted
      final currentStatus = await Permission.notification.status;
      if (currentStatus.isGranted) {
        logger.d('[NotificationPermissionService] Permission already granted');
        await _prefs.setBool(_notificationPermissionRequestedKey, true);
        return true;
      }

      // Check if permission is permanently denied
      if (currentStatus.isPermanentlyDenied) {
        logger.d(
          '[NotificationPermissionService] Permission permanently denied',
        );
        await _prefs.setBool(_notificationPermissionRequestedKey, true);
        return false;
      }

      // Request permission
      logger.d(
        '[NotificationPermissionService] Requesting notification permission',
      );
      final status = await Permission.notification.request();

      // Mark that permission has been requested
      await _prefs.setBool(_notificationPermissionRequestedKey, true);

      if (status.isGranted) {
        logger.d('[NotificationPermissionService] Permission granted');
        return true;
      } else {
        logger.d('[NotificationPermissionService] Permission denied: $status');
        return false;
      }
    } catch (e) {
      logger.d(
        '[NotificationPermissionService] Error requesting permission: $e',
      );
      await _prefs.setBool(_notificationPermissionRequestedKey, true);
      return false;
    }
  }

  /// Request notification permission on first launch
  /// This should be called when the app starts for the first time
  Future<void> requestPermissionOnFirstLaunch() async {
    try {
      // Check if this is the first launch
      final firstLaunch = await isFirstLaunch();
      if (!firstLaunch) {
        logger.d(
          '[NotificationPermissionService] Not first launch, skipping permission request',
        );
        return;
      }

      // Check if permission has already been requested
      final hasRequested = await hasRequestedPermission();
      if (hasRequested) {
        logger.d(
          '[NotificationPermissionService] Permission already requested previously',
        );
        return;
      }

      // Check if permission is already granted
      final isGranted = await isPermissionGranted();
      if (isGranted) {
        logger.d('[NotificationPermissionService] Permission already granted');
        await _prefs.setBool(_notificationPermissionRequestedKey, true);
        return;
      }

      // Request permission
      logger.d(
        '[NotificationPermissionService] Requesting notification permission on first launch',
      );
      await requestPermission();
    } catch (e) {
      logger.d(
        '[NotificationPermissionService] Error in requestPermissionOnFirstLaunch: $e',
      );
    }
  }
}
