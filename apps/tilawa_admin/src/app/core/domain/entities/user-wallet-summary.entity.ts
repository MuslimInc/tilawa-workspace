export type WalletStatus = 'active' | 'frozen' | 'closed';

export interface UserWalletSummary {
  walletId: string;
  userId: string;
  currency: string;
  status: WalletStatus;
  availableBalance: number;
  heldBalance: number;
  lastTransactionAt: Date | null;
}

export interface WalletTransactionSummary {
  id: string;
  walletId: string;
  userId: string;
  type: string;
  direction: 'credit' | 'debit';
  amount: number;
  currency: string;
  description: string;
  balanceAfter: number | null;
  sourceId: string | null;
  createdAt: Date;
}

export interface UserWalletDetail {
  wallet: UserWalletSummary | null;
  transactions: WalletTransactionSummary[];
  transactionsHasMore: boolean;
  transactionsNextCursor: string | null;
}

export const WALLET_TRANSACTION_DEFAULT_SORT = {
  field: 'createdAt',
  direction: 'desc',
} as const;

export const WALLET_TRANSACTION_SORT_FIELDS = ['createdAt'] as const;
