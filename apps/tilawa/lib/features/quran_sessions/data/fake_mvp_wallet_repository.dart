import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeMvpWalletRepository implements WalletRepository {
  const FakeMvpWalletRepository();

  @override
  Future<Either<QuranSessionsFailure, WalletSnapshot>> getWalletSnapshot(
    String userId,
  ) async {
    return const Right(
      WalletSnapshot(userId: 'student_mvp', wallet: null, transactions: []),
    );
  }
}
