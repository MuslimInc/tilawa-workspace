import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_wallet.dart';
import '../../../domain/entities/wallet_transaction.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

final class WalletInitial extends WalletState {
  const WalletInitial();
}

final class WalletLoading extends WalletState {
  const WalletLoading();
}

final class WalletSuccess extends WalletState {
  const WalletSuccess({
    required this.wallet,
    required this.transactions,
  });

  final UserWallet? wallet;
  final List<WalletTransaction> transactions;

  @override
  List<Object?> get props => [wallet, transactions];
}

final class WalletFailure extends WalletState {
  const WalletFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
