import 'package:injectable/injectable.dart';

import '../../../premium/data/datasources/premium_local_datasource.dart';
import '../repositories/auth_repository.dart';
import 'sync_device_token_use_case.dart';

@injectable
class SignOut {
  SignOut(
    this._repository,
    this._syncDeviceTokenUseCase,
    this._premiumLocalDataSource,
  );
  final AuthRepository _repository;
  final SyncDeviceTokenUseCase _syncDeviceTokenUseCase;
  final PremiumLocalDataSource _premiumLocalDataSource;

  Future<void> call() async {
    final currentUser = _repository.currentUser;
    try {
      if (currentUser != null) {
        await _syncDeviceTokenUseCase.removeCurrentTokenForUser(currentUser.id);
      }
      await _premiumLocalDataSource.clearPremiumStatus();
    } finally {
      await _repository.signOut();
    }
  }
}
