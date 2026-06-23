import 'package:equatable/equatable.dart';

enum WalletStatus { active, frozen, closed }

/// Student wallet aggregate (read-only in Phase 1).
class UserWallet extends Equatable {
  const UserWallet({
    required this.walletId,
    required this.userId,
    required this.currency,
    required this.status,
    required this.availableBalance,
    required this.heldBalance,
    this.lastTransactionAt,
  });

  final String walletId;
  final String userId;
  final String currency;
  final WalletStatus status;
  final double availableBalance;
  final double heldBalance;
  final DateTime? lastTransactionAt;

  bool get isFrozen => status == WalletStatus.frozen;

  @override
  List<Object?> get props => [
    walletId,
    userId,
    currency,
    status,
    availableBalance,
    heldBalance,
    lastTransactionAt,
  ];
}
