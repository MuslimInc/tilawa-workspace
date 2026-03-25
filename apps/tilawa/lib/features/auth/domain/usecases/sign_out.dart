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

  Future<void> call() async {
    final currentUser = _repository.currentUser;
    try {
      if (currentUser != null) {
        await _syncDeviceTokenUseCase.removeCurrentTokenForUser(currentUser.id);
      }
      await _premiumRepository.clearPremiumStatus();
    } finally {
      await _repository.signOut();
    }
  }
}
