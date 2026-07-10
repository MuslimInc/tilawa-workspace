import { Injectable, inject, signal } from '@angular/core';

import { AuthFacade } from './auth.facade';
import { ListTilawaUsersUseCase } from '../../domain/usecases/tilawa-user.usecases';
import { AUTH_ADMIN_GATEWAY } from '../../domain/repositories/auth-admin.gateway';
import { RequestUserDeletionUseCase } from '../../domain/usecases/user-deletion.usecases';
import { I18nService } from '../../i18n/i18n.service';
import {
  TILAWA_USER_DEFAULT_SORT,
  TilawaUserFilters,
} from '../../domain/entities/tilawa-user.entity';
import { DEFAULT_PAGE_SIZE, SortRequest, sortsEqual } from '../../domain/entities/pagination.types';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

function countEmailsByNormalizedAddress(
  users: readonly { email: string | null }[],
): Map<string, number> {
  const counts = new Map<string, number>();
  for (const user of users) {
    const email = user.email?.trim().toLowerCase();
    if (!email) {
      continue;
    }
    counts.set(email, (counts.get(email) ?? 0) + 1);
  }
  return counts;
}

export interface TilawaUserListItemVm {
  readonly id: string;
  readonly email: string;
  readonly displayName: string;
  readonly photoUrl: string | null;
  readonly createdAt: Date | null;
  readonly isAdmin: boolean;
  readonly hasAuthAccount: boolean;
  readonly hasDuplicateEmail: boolean;
}

@Injectable({ providedIn: 'root' })
export class TilawaUsersFacade {
  private readonly listUseCase = inject(ListTilawaUsersUseCase);
  private readonly requestDeletionUseCase = inject(RequestUserDeletionUseCase);
  private readonly authAdminGateway = inject(AUTH_ADMIN_GATEWAY);
  private readonly authFacade = inject(AuthFacade);
  private readonly i18n = inject(I18nService);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<TilawaUserListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly actionLoading = signal(false);
  private readonly actionError = signal<string | null>(null);
  private readonly listSort = signal<SortRequest>(TILAWA_USER_DEFAULT_SORT);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();
  readonly actionErrorMessage = this.actionError.asReadonly();
  readonly sort = this.listSort.asReadonly();

  async loadList(
    filters: TilawaUserFilters,
    options?: {
      cursor?: string | null;
      append?: boolean;
      sort?: SortRequest;
    },
  ): Promise<void> {
    const sort = options?.sort ?? this.listSort();
    const sortChanged = !sortsEqual(sort, this.listSort());
    const append = options?.append === true && !sortChanged;
    const cursor = append ? (options?.cursor ?? this.nextCursor()) : null;

    this.listSort.set(sort);
    this.listState.set('loading');
    this.listError.set(null);

    try {
      const page = await this.listUseCase.execute(filters, {
        pageSize: DEFAULT_PAGE_SIZE,
        cursor,
        sort,
      });

      const mapped = page.items.map((user) => this.toListItem(user));
      const combined = append ? [...this.listItems(), ...mapped] : mapped;
      const enriched = this.markDuplicateEmails(await this.enrichWithAdminClaims(combined));
      this.listItems.set(enriched);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(error instanceof Error ? error.message : 'Failed to load users.');
    }
  }

  async loadMore(filters: TilawaUserFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, {
      cursor: this.nextCursor(),
      append: true,
      sort: this.listSort(),
    });
  }

  async changeSort(filters: TilawaUserFilters, sort: SortRequest): Promise<void> {
    await this.loadList(filters, { sort, append: false, cursor: null });
  }

  clearActionError(): void {
    this.actionError.set(null);
  }

  async requestUserDeletion(userId: string, reason: string, confirmEmail: string): Promise<void> {
    this.actionLoading.set(true);
    this.actionError.set(null);
    try {
      await this.requestDeletionUseCase.execute(userId, reason, confirmEmail);
    } catch (error) {
      this.actionError.set(this.mapDeletionError(error));
      throw error;
    } finally {
      this.actionLoading.set(false);
    }
  }

  private toListItem(user: {
    id: string;
    email: string | null;
    displayName: string | null;
    photoUrl: string | null;
    createdAt: Date | null;
  }): TilawaUserListItemVm {
    return {
      id: user.id,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      isAdmin: false,
      hasAuthAccount: true,
      hasDuplicateEmail: false,
    };
  }

  private markDuplicateEmails(items: TilawaUserListItemVm[]): TilawaUserListItemVm[] {
    const emailCounts = countEmailsByNormalizedAddress(items);
    return items.map((user) => {
      const normalizedEmail = user.email.trim().toLowerCase();
      const hasDuplicateEmail =
        normalizedEmail.length > 0 && (emailCounts.get(normalizedEmail) ?? 0) > 1;
      return { ...user, hasDuplicateEmail };
    });
  }

  private mapDeletionError(error: unknown): string {
    const message = error instanceof Error ? error.message : '';
    if (
      message.includes('Firestore but has no Firebase Auth account') ||
      message === 'Target user not found.'
    ) {
      return this.i18n.t('userDeletion_error_authAccountMissing');
    }
    if (message.includes('is not deployed')) {
      return this.i18n.t('userDeletion_error_notDeployed', {
        functionName: 'requestUserDeletion',
      });
    }
    return message || this.i18n.t('userDeletion_error_generic');
  }

  private async enrichWithAdminClaims(
    items: TilawaUserListItemVm[],
  ): Promise<TilawaUserListItemVm[]> {
    if (items.length === 0) {
      return items;
    }

    const adminUserIds = new Set<string>();
    const authBackedUserIds = new Set<string>();
    try {
      const metadata = await this.authAdminGateway.lookupUserAuthMetadata(
        items.map((user) => user.id),
      );
      for (const uid of metadata.adminUserIds) {
        adminUserIds.add(uid);
      }
      for (const uid of metadata.authBackedUserIds) {
        authBackedUserIds.add(uid);
      }
    } catch (error) {
      console.warn(
        '[TilawaUsersFacade] lookupUserAdminClaims failed; using session fallback only.',
        error,
      );
    }

    const session = this.authFacade.session();
    if (session?.isAdmin) {
      adminUserIds.add(session.uid);
    }

    return items.map((user) => ({
      ...user,
      isAdmin: adminUserIds.has(user.id),
      hasAuthAccount: authBackedUserIds.has(user.id),
    }));
  }
}
