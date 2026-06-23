import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository(this._snapshot);

  FakeWalletRepository.empty()
    : _snapshot = const WalletSnapshot(
        userId: 'student1',
        wallet: null,
        transactions: [],
      );

  final WalletSnapshot _snapshot;

  @override
  Future<Either<QuranSessionsFailure, WalletSnapshot>> getWalletSnapshot(
    String userId,
  ) async {
    return Right(_snapshot);
  }
}
