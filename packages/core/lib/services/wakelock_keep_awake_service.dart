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
    } on PlatformException catch (e) {
      if (!isNoActivityPlatformException(e)) rethrow;
    } finally {
      _enabled = false;
    }
  }

  @override
  Future<bool> get isEnabled async => _enabled;
}

@visibleForTesting
bool isNoActivityPlatformException(PlatformException exception) =>
    exception.code == 'NoActivityException';
