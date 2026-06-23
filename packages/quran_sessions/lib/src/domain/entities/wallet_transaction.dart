import 'package:equatable/equatable.dart';

enum WalletTransactionDirection { credit, debit }

enum WalletTransactionType {
  refundCredit,
  compensationCredit,
  adminCredit,
  promoCredit,
  bookingDebit,
  hold,
  holdRelease,
  adminReversal,
  expiryDebit,
}

/// Immutable wallet ledger row (read-only in Phase 1).
class WalletTransaction extends Equatable {
  const WalletTransaction({
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
  final WalletTransactionType type;
  final WalletTransactionDirection direction;
  final double amount;
  final String currency;
  final String description;
  final DateTime createdAt;
  final double? balanceAfter;
  final String? sourceId;

  @override
  List<Object?> get props => [
    transactionId,
    walletId,
    userId,
    type,
    direction,
    amount,
    currency,
    description,
    createdAt,
    balanceAfter,
    sourceId,
  ];
}
