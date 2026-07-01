import { Injectable, inject, signal } from '@angular/core';

import {
  DuplicateAccountsLookupResult,
  DuplicateAuthAccount,
} from '../../domain/entities/duplicate-auth-account.entity';
import {
  LookupDuplicateAccountsByEmailUseCase,
  RequestDuplicateAccountsDeletionUseCase,
} from '../../domain/usecases/user-deletion.usecases';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class DuplicateAccountsFacade {
  private readonly lookupUseCase = inject(LookupDuplicateAccountsByEmailUseCase);
  private readonly deleteUseCase = inject(RequestDuplicateAccountsDeletionUseCase);

  private readonly lookupState = signal<LoadState>('idle');
  private readonly lookupError = signal<string | null>(null);
  private readonly lookupResult = signal<DuplicateAccountsLookupResult | null>(
    null,
  );
  private readonly actionLoading = signal(false);
  private readonly actionError = signal<string | null>(null);

  readonly loadState = this.lookupState.asReadonly();
  readonly errorMessage = this.lookupError.asReadonly();
  readonly result = this.lookupResult.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();
  readonly actionErrorMessage = this.actionError.asReadonly();

  async lookupByEmail(email: string): Promise<void> {
    this.lookupState.set('loading');
    this.lookupError.set(null);
    try {
      const result = await this.lookupUseCase.execute(email.trim());
      this.lookupResult.set(result);
      this.lookupState.set('success');
    } catch (error) {
      this.lookupState.set('error');
      this.lookupError.set(
        error instanceof Error ? error.message : 'Lookup failed.',
      );
    }
  }

  applyKeepGooglePlan(): {
    keepUserId: string;
    deleteUserIds: string[];
  } | null {
    const plan = this.lookupResult()?.suggestedKeepGooglePlan;
    if (!plan) return null;
    return {
      keepUserId: plan.keepUserId,
      deleteUserIds: [...plan.deleteUserIds],
    };
  }

  async requestDeletion(input: {
    email: string;
    reason: string;
    confirmEmail: string;
    keepUserId: string;
    deleteUserIds: readonly string[];
    forceDeleteGoogleAccount?: boolean;
  }): Promise<void> {
    this.actionLoading.set(true);
    this.actionError.set(null);
    try {
      await this.deleteUseCase.execute(input);
      await this.lookupByEmail(input.email);
    } catch (error) {
      this.actionError.set(
        error instanceof Error ? error.message : 'Deletion request failed.',
      );
      throw error;
    } finally {
      this.actionLoading.set(false);
    }
  }

  googleAccountCount(accounts: readonly DuplicateAuthAccount[]): number {
    return accounts.filter((account) => account.hasGoogleProvider).length;
  }
}
