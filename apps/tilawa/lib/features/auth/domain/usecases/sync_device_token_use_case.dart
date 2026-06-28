import 'package:injectable/injectable.dart';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'register_active_device_use_case.dart';

@injectable
class SyncDeviceTokenUseCase {
  SyncDeviceTokenUseCase(this._registerActiveDeviceUseCase);

  final RegisterActiveDeviceUseCase _registerActiveDeviceUseCase;

  Future<Either<Failure, void>> call(String userId) async {
    final result = await _registerActiveDeviceUseCase(userId);
    return result.fold(Left.new, (_) => const Right(null));
  }

  Future<void> removeCurrentTokenForUser(String userId) async {
    try {
      await _registerActiveDeviceUseCase.clearActiveDeviceOnSignOut(userId);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}
