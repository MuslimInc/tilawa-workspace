import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'interfaces/keep_awake_service.dart';

/// Implementation of [KeepAwakeService] using the `wakelock_plus` plugin.
@LazySingleton(as: KeepAwakeService)
class WakelockKeepAwakeService implements KeepAwakeService {
  bool _enabled = false;

  @visibleForTesting
  Future<void> Function()? wakelockEnable;

  @visibleForTesting
  Future<void> Function()? wakelockDisable;

  @override
  Future<void> enable() async {
    if (_enabled) return;

    try {
      await (wakelockEnable ?? WakelockPlus.enable)();
      _enabled = true;
    } on PlatformException catch (e) {
      if (!isNoActivityPlatformException(e)) rethrow;
    }
  }

  @override
  Future<void> disable() async {
    if (!_enabled) return;

    try {
      await (wakelockDisable ?? WakelockPlus.disable)();
    } on PlatformException {
      // Activity may already be gone during background or teardown.
    } finally {
      _enabled = false;
    }
  }

  @override
  Future<bool> get isEnabled async => _enabled;
}

@visibleForTesting
String platformExceptionDescription(PlatformException exception) {
  return <String?>[
    exception.message,
    exception.details?.toString(),
    exception.toString(),
  ].whereType<String>().join(' ');
}

@visibleForTesting
bool isNoActivityPlatformException(PlatformException exception) {
  if (exception.code == 'NoActivityException') {
    return true;
  }

  final String description = platformExceptionDescription(exception);
  if (description.contains('foreground activity')) {
    return true;
  }

  // Release ProGuard maps NoActivityException to short codes such as `d`.
  return exception.code == 'd' && description.contains('wakelock');
}

/// True for wakelock/no-foreground-activity noise that must not reach crash
/// reporters (Sentry, Crashlytics) when lifecycle races the Android activity.
bool isIgnorableWakelockPlatformNoise(Object error) {
  if (error is PlatformException && isNoActivityPlatformException(error)) {
    return true;
  }

  final String description = error.toString();
  return description.contains('wakelock') &&
      description.contains('foreground activity');
}
