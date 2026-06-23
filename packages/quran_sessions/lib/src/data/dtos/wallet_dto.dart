class WalletSnapshotDto {
  const WalletSnapshotDto({
    required this.userId,
    this.wallet,
    required this.transactions,
  });

  final String userId;
  final WalletDto? wallet;
  final List<WalletTransactionDto> transactions;
}

class WalletDto {
  const WalletDto({
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
  final String status;
  final double availableBalance;
  final double heldBalance;
  final DateTime? lastTransactionAt;
}

class WalletTransactionDto {
  const WalletTransactionDto({
    required this.transactionId,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
    this.balanceAfter,
    this.sourceId,
  });

  final String transactionId;
  final String walletId;
  final String userId;
  final String type;
  final String direction;
  final double amount;
  final String currency;
  final String description;
  final DateTime createdAt;
  final double? balanceAfter;
  final String? sourceId;
}
