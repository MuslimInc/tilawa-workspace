import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_wallet.dart';
import '../entities/wallet_transaction.dart';
import '../failures/quran_sessions_failure.dart';

class WalletSnapshot {
  const WalletSnapshot({
    required this.userId,
    this.wallet,
    required this.transactions,
  });

  final String userId;
  final UserWallet? wallet;
  final List<WalletTransaction> transactions;
}

abstract interface class WalletRepository {
  Future<Either<QuranSessionsFailure, WalletSnapshot>> getWalletSnapshot(
    String userId,
  );
}
