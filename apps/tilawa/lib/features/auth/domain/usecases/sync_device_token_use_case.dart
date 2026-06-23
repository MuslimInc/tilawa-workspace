import 'package:injectable/injectable.dart';

import 'register_active_device_use_case.dart';

@injectable
class SyncDeviceTokenUseCase {
  SyncDeviceTokenUseCase(this._registerActiveDeviceUseCase);

  final RegisterActiveDeviceUseCase _registerActiveDeviceUseCase;

  Future<void> call(String userId) async {
    final result = await _registerActiveDeviceUseCase(userId);
    result.fold((_) => null, (_) => null);
  }

  Future<void> removeCurrentTokenForUser(String userId) async {
    try {
      await _registerActiveDeviceUseCase.clearActiveDeviceOnSignOut(userId);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}
