import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  where,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  UserWalletDetail,
  UserWalletSummary,
  WalletTransactionSummary,
} from '../../domain/entities/user-wallet-summary.entity';
import { WalletReadRepository } from '../../domain/repositories/wallet-read.repository';

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

  async getByUserId(userId: string): Promise<UserWalletDetail> {
    const walletId = `wallet_${userId}`;
    const walletSnap = await getDoc(
      doc(this.firestore, QuranSessionsPaths.userWallets, walletId),
    );

    const transactionsSnap = await getDocs(
      query(
        collection(this.firestore, QuranSessionsPaths.walletTransactions),
        where('userId', '==', userId),
        orderBy('createdAt', 'desc'),
        limit(50),
      ),
    );

    return {
      wallet: walletSnap.exists()
        ? this.mapWallet(walletSnap.id, walletSnap.data())
        : null,
      transactions: transactionsSnap.docs.map((snap) =>
        this.mapTransaction(snap.id, snap.data()),
      ),
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
