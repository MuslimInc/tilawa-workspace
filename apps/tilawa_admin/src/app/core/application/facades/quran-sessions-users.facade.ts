import { Injectable, inject, signal } from '@angular/core';

import {
  ListQuranSessionsUsersUseCase,
  ModerateQuranSessionsUserUseCase,
  SetUserTeacherApplicationAccessUseCase,
} from '../../domain/usecases/quran-sessions-user.usecases';
import {
  QS_USER_DEFAULT_SORT,
  QuranSessionsUserFilters,
} from '../../domain/entities/quran-sessions-user.entity';
import { UserModerationAction } from '../../domain/entities/moderation-action.enum';
import {
  QuranSessionsUserListItemVm,
  QuranSessionsViewModelMapper,
} from '../../data/view-models/quran-sessions.view-model';
import {
  DEFAULT_PAGE_SIZE,
  SortRequest,
  sortsEqual,
} from '../../domain/entities/pagination.types';

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
  private readonly teacherAccessUseCase = inject(
    SetUserTeacherApplicationAccessUseCase,
  );

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<QuranSessionsUserListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly actionLoading = signal(false);
  private readonly listSort = signal<SortRequest>(QS_USER_DEFAULT_SORT);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();
  readonly sort = this.listSort.asReadonly();

  async loadList(
    filters: QuranSessionsUserFilters,
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
    await this.loadList(filters, {
      cursor: this.nextCursor(),
      append: true,
      sort: this.listSort(),
    });
  }

  async changeSort(
    filters: QuranSessionsUserFilters,
    sort: SortRequest,
  ): Promise<void> {
    await this.loadList(filters, { sort, append: false, cursor: null });
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

  async reactivateUser(userId: string): Promise<void> {
    this.actionLoading.set(true);
    try {
      await this.moderateUseCase.execute(
        userId,
        UserModerationAction.Reactivate,
      );
    } finally {
      this.actionLoading.set(false);
    }
  }

  async setTeacherApplicationAccess(
    userId: string,
    canApplyAsTeacher: boolean | null,
  ): Promise<void> {
    this.actionLoading.set(true);
    try {
      await this.teacherAccessUseCase.execute(userId, canApplyAsTeacher);
      this.listItems.update((items) =>
        items.map((item) =>
          item.userId === userId
            ? { ...item, canApplyAsTeacher }
            : item,
        ),
      );
    } finally {
      this.actionLoading.set(false);
    }
  }
}
