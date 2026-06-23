import '../../domain/entities/user_wallet.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../dtos/wallet_dto.dart';

abstract final class WalletMapper {
  static UserWallet? toEntity(WalletDto? dto) {
    if (dto == null) return null;
    return UserWallet(
      walletId: dto.walletId,
      userId: dto.userId,
      currency: dto.currency,
      status: _walletStatus(dto.status),
      availableBalance: dto.availableBalance,
      heldBalance: dto.heldBalance,
      lastTransactionAt: dto.lastTransactionAt,
    );
  }

  static WalletTransaction toTransactionEntity(WalletTransactionDto dto) {
    return WalletTransaction(
      transactionId: dto.transactionId,
      walletId: dto.walletId,
      userId: dto.userId,
      type: _transactionType(dto.type),
      direction: dto.direction == 'debit'
          ? WalletTransactionDirection.debit
          : WalletTransactionDirection.credit,
      amount: dto.amount,
      currency: dto.currency,
      description: dto.description,
      createdAt: dto.createdAt,
      balanceAfter: dto.balanceAfter,
      sourceId: dto.sourceId,
    );
  }

  static WalletStatus _walletStatus(String raw) => switch (raw) {
    'frozen' => WalletStatus.frozen,
    'closed' => WalletStatus.closed,
    _ => WalletStatus.active,
  };

  static WalletTransactionType _transactionType(String raw) => switch (raw) {
    'compensation_credit' => WalletTransactionType.compensationCredit,
    'admin_credit' => WalletTransactionType.adminCredit,
    'promo_credit' => WalletTransactionType.promoCredit,
    'booking_debit' => WalletTransactionType.bookingDebit,
    'hold' => WalletTransactionType.hold,
    'hold_release' => WalletTransactionType.holdRelease,
    'admin_reversal' => WalletTransactionType.adminReversal,
    'expiry_debit' => WalletTransactionType.expiryDebit,
    _ => WalletTransactionType.refundCredit,
  };
}
