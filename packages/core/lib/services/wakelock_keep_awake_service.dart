import 'package:injectable/injectable.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'interfaces/keep_awake_service.dart';

/// Implementation of [KeepAwakeService] using the `wakelock_plus` plugin.
@LazySingleton(as: KeepAwakeService)
class WakelockKeepAwakeService implements KeepAwakeService {
  @override
  Future<void> enable() async {
    await WakelockPlus.enable();
  }

  @override
  Future<void> disable() async {
    await WakelockPlus.disable();
  }

  @override
  Future<bool> get isEnabled async {
    return WakelockPlus.enabled;
  }
}
