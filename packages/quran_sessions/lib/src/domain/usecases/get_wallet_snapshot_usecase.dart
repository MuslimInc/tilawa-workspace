import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';
import '../repositories/wallet_repository.dart';

class GetWalletSnapshotUseCase {
  const GetWalletSnapshotUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<QuranSessionsFailure, WalletSnapshot>> call(String userId) {
    return _repository.getWalletSnapshot(userId);
  }
}
