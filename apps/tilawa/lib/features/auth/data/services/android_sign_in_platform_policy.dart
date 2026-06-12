import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/auth/core/android_credential_manager_oem_policy.dart';

/// Resolves whether this Android build must avoid automatic sign-in flows.
@lazySingleton
class AndroidSignInPlatformPolicy {
  AndroidSignInPlatformPolicy({DeviceInfoPlugin? deviceInfoPlugin})
    : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
      _isAndroid = Platform.isAndroid;

  @visibleForTesting
  AndroidSignInPlatformPolicy.test({
    required this.skipAutomaticSignIn,
  }) : _deviceInfoPlugin = null,
       _isAndroid = false,
       _warmUpComplete = true;

  /// Allows host tests to exercise the Android-only warm-up path.
  @visibleForTesting
  AndroidSignInPlatformPolicy.forPlatform({
    required DeviceInfoPlugin deviceInfoPlugin,
    required bool isAndroid,
  }) : _deviceInfoPlugin = deviceInfoPlugin,
       _isAndroid = isAndroid;

  final DeviceInfoPlugin? _deviceInfoPlugin;
  final bool _isAndroid;

  /// Transsion OEMs: skip auto sign-in and silent auth — their Play Services
  /// sign-in UI can stay invisible behind the Flutter surface.
  bool skipAutomaticSignIn = false;
  bool _warmUpComplete = false;
  Future<void>? _warmUpFuture;

  /// Loads OEM info once; safe to call concurrently.
  Future<void> warmUp() {
    if (!_isAndroid) {
      _warmUpComplete = true;
      return Future<void>.value();
    }
    if (_deviceInfoPlugin == null) {
      _warmUpComplete = true;
      return Future<void>.value();
    }
    return _warmUpFuture ??= _runWarmUp();
  }

  Future<void> _runWarmUp() async {
    try {
      final AndroidDeviceInfo info = await _deviceInfoPlugin!.androidInfo;
      skipAutomaticSignIn = AndroidCredentialManagerOemPolicy
          .shouldSkipAutomaticSignIn(
        manufacturer: info.manufacturer,
        brand: info.brand,
      );
      if (skipAutomaticSignIn) {
        logger.i(
          '[GoogleSignIn] OEM (${info.manufacturer}/${info.brand}) '
          'automatic sign-in disabled (invisible picker workaround)',
        );
      }
    } catch (error) {
      logger.d('[GoogleSignIn] OEM policy warm-up failed: $error');
    } finally {
      _warmUpComplete = true;
    }
  }

  @visibleForTesting
  void resetForTesting() {
    skipAutomaticSignIn = false;
    _warmUpComplete = false;
    _warmUpFuture = null;
  }

  @visibleForTesting
  bool get isWarmUpComplete => _warmUpComplete;
}
