import { Injectable, inject, signal } from '@angular/core';

import { GetUserWalletUseCase } from '../../domain/usecases/wallet.usecases';
import { DEFAULT_PAGE_SIZE, SortRequest, sortsEqual } from '../../domain/entities/pagination.types';
import {
  UserWalletDetail,
  WALLET_TRANSACTION_DEFAULT_SORT,
} from '../../domain/entities/user-wallet-summary.entity';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class UserWalletsFacade {
  private readonly getUseCase = inject(GetUserWalletUseCase);

  private readonly detailState = signal<LoadState>('idle');
  private readonly detailError = signal<string | null>(null);
  private readonly detailItem = signal<UserWalletDetail | null>(null);
  private readonly activeUserId = signal<string | null>(null);
  private readonly txnCursor = signal<string | null>(null);
  private readonly txnHasMore = signal(false);
  private readonly txnSort = signal<SortRequest>(WALLET_TRANSACTION_DEFAULT_SORT);

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();
  readonly userId = this.activeUserId.asReadonly();
  readonly canLoadMoreTransactions = this.txnHasMore.asReadonly();

  async loadForUser(userId: string): Promise<void> {
    const trimmed = userId.trim();
    if (!trimmed) {
      this.detailState.set('error');
      this.detailError.set('User ID is required.');
      this.detailItem.set(null);
      return;
    }

    this.activeUserId.set(trimmed);
    this.txnCursor.set(null);
    this.detailState.set('loading');
    this.detailError.set(null);

    try {
      const detail = await this.getUseCase.execute(trimmed, {
        pageSize: DEFAULT_PAGE_SIZE,
        cursor: null,
        sort: this.txnSort(),
      });
      this.detailItem.set(detail);
      this.txnCursor.set(detail.transactionsNextCursor);
      this.txnHasMore.set(detail.transactionsHasMore);
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(error instanceof Error ? error.message : 'Failed to load wallet.');
    }
  }

  async loadMoreTransactions(): Promise<void> {
    const userId = this.activeUserId();
    const cursor = this.txnCursor();
    if (!userId || !this.txnHasMore() || !cursor) {
      return;
    }

    this.detailState.set('loading');
    try {
      const page = await this.getUseCase.execute(userId, {
        pageSize: DEFAULT_PAGE_SIZE,
        cursor,
        sort: this.txnSort(),
      });
      const current = this.detailItem();
      if (!current) {
        return;
      }

      this.detailItem.set({
        ...current,
        transactions: [...current.transactions, ...page.transactions],
        transactionsHasMore: page.transactionsHasMore,
        transactionsNextCursor: page.transactionsNextCursor,
      });
      this.txnCursor.set(page.transactionsNextCursor);
      this.txnHasMore.set(page.transactionsHasMore);
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(error instanceof Error ? error.message : 'Failed to load transactions.');
    }
  }

  async changeTransactionSort(sort: SortRequest): Promise<void> {
    const userId = this.activeUserId();
    if (!userId || sortsEqual(sort, this.txnSort())) {
      return;
    }
    this.txnSort.set(sort);
    await this.loadForUser(userId);
  }
}
