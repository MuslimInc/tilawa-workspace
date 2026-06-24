import { Injectable, inject, signal } from '@angular/core';

import { ListTilawaUsersUseCase } from '../../domain/usecases/tilawa-user.usecases';
import {
  TILAWA_USER_DEFAULT_SORT,
  TilawaUserFilters,
} from '../../domain/entities/tilawa-user.entity';
import {
  DEFAULT_PAGE_SIZE,
  SortRequest,
  sortsEqual,
} from '../../domain/entities/pagination.types';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

export interface TilawaUserListItemVm {
  readonly id: string;
  readonly email: string;
  readonly displayName: string;
  readonly photoUrl: string | null;
  readonly createdAt: Date | null;
}

@Injectable({ providedIn: 'root' })
export class TilawaUsersFacade {
  private readonly listUseCase = inject(ListTilawaUsersUseCase);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<TilawaUserListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly listSort = signal<SortRequest>(TILAWA_USER_DEFAULT_SORT);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
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

  async changeSort(
    filters: TilawaUserFilters,
    sort: SortRequest,
  ): Promise<void> {
    await this.loadList(filters, { sort, append: false, cursor: null });
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
    };
  }
}
