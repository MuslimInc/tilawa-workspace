import { Injectable, inject } from '@angular/core';
import { Firestore, doc, getDoc, where } from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  UserWalletDetail,
  UserWalletSummary,
  WALLET_TRANSACTION_DEFAULT_SORT,
  WALLET_TRANSACTION_SORT_FIELDS,
  WalletTransactionSummary,
} from '../../domain/entities/user-wallet-summary.entity';
import {
  DEFAULT_PAGE_SIZE,
  PageRequest,
} from '../../domain/entities/pagination.types';
import { WalletReadRepository } from '../../domain/repositories/wallet-read.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';

function readTimestamp(value: unknown): Date | null {
  if (
    value != null &&
    typeof value === 'object' &&
    'toDate' in value &&
    typeof (value as { toDate: () => Date }).toDate === 'function'
  ) {
    return (value as { toDate: () => Date }).toDate();
  }
  return null;
}

function readAmount(value: unknown): number {
  return typeof value === 'number' ? value : 0;
}

@Injectable({ providedIn: 'root' })
export class FirebaseWalletReadRepository implements WalletReadRepository {
  private readonly firestore = inject(Firestore);

  async getByUserId(
    userId: string,
    transactionsPage?: PageRequest,
  ): Promise<UserWalletDetail> {
    const walletId = `wallet_${userId}`;
    const walletSnap = await getDoc(
      doc(this.firestore, QuranSessionsPaths.userWallets, walletId),
    );

    const page = transactionsPage ?? { pageSize: DEFAULT_PAGE_SIZE };
    const txnPage = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.walletTransactions,
      filters: [where('userId', '==', userId)],
      page,
      defaultSort: WALLET_TRANSACTION_DEFAULT_SORT,
      allowedSortFields: WALLET_TRANSACTION_SORT_FIELDS,
      mapDoc: (id, data) => this.mapTransaction(id, data),
    });

    return {
      wallet: walletSnap.exists()
        ? this.mapWallet(walletSnap.id, walletSnap.data())
        : null,
      transactions: [...txnPage.items],
      transactionsHasMore: txnPage.hasMore,
      transactionsNextCursor: txnPage.nextCursor,
    };
  }

  private mapWallet(
    walletId: string,
    data: Record<string, unknown>,
  ): UserWalletSummary {
    return {
      walletId,
      userId: String(data['userId'] ?? ''),
      currency: String(data['currency'] ?? 'EGP'),
      status: (data['status'] as UserWalletSummary['status']) ?? 'active',
      availableBalance: readAmount(data['availableBalance']),
      heldBalance: readAmount(data['heldBalance']),
      lastTransactionAt: readTimestamp(data['lastTransactionAt']),
    };
  }

  private mapTransaction(
    id: string,
    data: Record<string, unknown>,
  ): WalletTransactionSummary {
    return {
      id,
      walletId: String(data['walletId'] ?? ''),
      userId: String(data['userId'] ?? ''),
      type: String(data['type'] ?? ''),
      direction: data['direction'] === 'debit' ? 'debit' : 'credit',
      amount: readAmount(data['amount']),
      currency: String(data['currency'] ?? 'EGP'),
      description: String(data['description'] ?? ''),
      balanceAfter:
        data['balanceAfter'] == null
          ? null
          : readAmount(data['balanceAfter']),
      sourceId: data['sourceId'] == null ? null : String(data['sourceId']),
      createdAt: readTimestamp(data['createdAt']) ?? new Date(0),
    };
  }
}
