import 'package:injectable/injectable.dart';

import '../../../premium/domain/repositories/premium_repository.dart';
import '../repositories/auth_repository.dart';
import 'sync_device_token_use_case.dart';

@injectable
class SignOut {
  SignOut(
    this._repository,
    this._syncDeviceTokenUseCase,
    this._premiumRepository,
  );
  final AuthRepository _repository;
  final SyncDeviceTokenUseCase _syncDeviceTokenUseCase;
  final PremiumRepository _premiumRepository;

  /// When [skipServerTokenClear] is true (remote session revoke), local sign-out
  /// must not call the server token-clear path that could race with a new device.
  Future<void> call({bool skipServerTokenClear = false}) async {
    final currentUser = _repository.currentUser;
    if (currentUser != null && !skipServerTokenClear) {
      try {
        await _syncDeviceTokenUseCase.removeCurrentTokenForUser(currentUser.id);
      } catch (_) {
        // Best-effort only; sign-out must still complete.
      }
    }
    await _premiumRepository.clearPremiumStatus();
    await _repository.signOut();
  }
}
