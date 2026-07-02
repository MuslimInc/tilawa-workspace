import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/domain/server_action_guard.dart';
import '../../../premium/domain/repositories/premium_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/token_sync_cache.dart';
import 'sync_device_token_use_case.dart';

@injectable
class SignOut {
  SignOut(
    this._repository,
    this._syncDeviceTokenUseCase,
    this._premiumRepository,
    this._tokenSyncCache,
    this._serverActionGuard,
  );
  final AuthRepository _repository;
  final SyncDeviceTokenUseCase _syncDeviceTokenUseCase;
  final PremiumRepository _premiumRepository;
  final TokenSyncCache _tokenSyncCache;
  final ServerActionGuard _serverActionGuard;

  /// When [skipServerTokenClear] is true (remote session revoke), local sign-out
  /// must not call the server token-clear path that could race with a new device.
  Future<Either<Failure, void>> call({
    bool skipServerTokenClear = false,
  }) async {
    if (!skipServerTokenClear) {
      final guardResult = await _serverActionGuard.ensureCanRun(
        ServerActionType.logout,
      );
      final Failure? blockedFailure = guardResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (blockedFailure != null) {
        return Left(blockedFailure);
      }
    }

    final currentUser = _repository.currentUser;
    if (currentUser != null && !skipServerTokenClear) {
      try {
        await _syncDeviceTokenUseCase.removeCurrentTokenForUser(currentUser.id);
      } catch (_) {
        // Best-effort only; sign-out must still complete.
      }
    }
    await _tokenSyncCache.clearSession();
    await _premiumRepository.clearPremiumStatus();
    await _repository.signOut();
    return const Right(null);
  }
}
