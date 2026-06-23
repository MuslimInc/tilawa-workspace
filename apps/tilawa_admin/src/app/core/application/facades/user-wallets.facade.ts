import { Injectable, inject, signal } from '@angular/core';

import { GetUserWalletUseCase } from '../../domain/usecases/wallet.usecases';
import { UserWalletDetail } from '../../domain/entities/user-wallet-summary.entity';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class UserWalletsFacade {
  private readonly getUseCase = inject(GetUserWalletUseCase);

  private readonly detailState = signal<LoadState>('idle');
  private readonly detailError = signal<string | null>(null);
  private readonly detailItem = signal<UserWalletDetail | null>(null);
  private readonly activeUserId = signal<string | null>(null);

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();
  readonly userId = this.activeUserId.asReadonly();

  async loadForUser(userId: string): Promise<void> {
    const trimmed = userId.trim();
    if (!trimmed) {
      this.detailState.set('error');
      this.detailError.set('User ID is required.');
      this.detailItem.set(null);
      return;
    }

    this.activeUserId.set(trimmed);
    this.detailState.set('loading');
    this.detailError.set(null);

    try {
      const detail = await this.getUseCase.execute(trimmed);
      this.detailItem.set(detail);
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(
        error instanceof Error ? error.message : 'Failed to load wallet.',
      );
    }
  }
}
