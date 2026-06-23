import { Injectable, inject, signal } from '@angular/core';

import {
  ListQuranSessionsUsersUseCase,
  ModerateQuranSessionsUserUseCase,
} from '../../domain/usecases/quran-sessions-user.usecases';
import { QuranSessionsUserFilters } from '../../domain/entities/quran-sessions-user.entity';
import { UserModerationAction } from '../../domain/entities/moderation-action.enum';
import {
  QuranSessionsUserListItemVm,
  QuranSessionsViewModelMapper,
} from '../../data/view-models/quran-sessions.view-model';

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

@Injectable({ providedIn: 'root' })
export class QuranSessionsUsersFacade {
  private readonly listUseCase = inject(ListQuranSessionsUsersUseCase);
  private readonly moderateUseCase = inject(ModerateQuranSessionsUserUseCase);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<QuranSessionsUserListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly actionLoading = signal(false);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();

  async loadList(
    filters: QuranSessionsUserFilters,
    cursor: string | null = null,
    append = false,
  ): Promise<void> {
    this.listState.set('loading');
    this.listError.set(null);

    try {
      const page = await this.listUseCase.execute(filters, {
        pageSize: 25,
        cursor,
      });

      const emailCounts = countEmailsByNormalizedAddress(page.items);
      const mapped = page.items.map((user) => {
        const normalizedEmail = user.email?.trim().toLowerCase() ?? '';
        const hasDuplicateEmail =
          normalizedEmail.length > 0 &&
          (emailCounts.get(normalizedEmail) ?? 0) > 1;
        return QuranSessionsViewModelMapper.toUserListItem(
          user,
          hasDuplicateEmail,
        );
      });

      this.listItems.set(append ? [...this.listItems(), ...mapped] : mapped);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(
        error instanceof Error ? error.message : 'Failed to load users.',
      );
    }
  }

  async loadMore(filters: QuranSessionsUserFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, this.nextCursor(), true);
  }

  async suspendUser(userId: string, reason: string): Promise<void> {
    this.actionLoading.set(true);
    try {
      await this.moderateUseCase.execute(
        userId,
        UserModerationAction.Suspend,
        reason,
      );
    } finally {
      this.actionLoading.set(false);
    }
  }
}
