import { Injectable, inject, signal } from '@angular/core';

import {
  ListTeachersUseCase,
  ModerateTeacherProfileUseCase,
} from '../../domain/usecases/teacher-profile.usecases';
import {
  TeacherProfileFilters,
  TEACHER_PROFILE_DEFAULT_SORT,
} from '../../domain/entities/teacher-profile.entity';
import { DEFAULT_PAGE_SIZE, SortRequest, sortsEqual } from '../../domain/entities/pagination.types';
import { TeacherProfileModerationAction } from '../../domain/entities/moderation-action.enum';
import {
  TeacherListItemVm,
  QuranSessionsViewModelMapper,
} from '../../data/view-models/quran-sessions.view-model';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class TeachersFacade {
  private readonly listUseCase = inject(ListTeachersUseCase);
  private readonly moderateUseCase = inject(ModerateTeacherProfileUseCase);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<TeacherListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly actionLoading = signal(false);
  private readonly listSort = signal<SortRequest>(TEACHER_PROFILE_DEFAULT_SORT);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();
  readonly sort = this.listSort.asReadonly();

  async loadList(
    filters: TeacherProfileFilters,
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

      const mapped = page.items.map((profile) =>
        QuranSessionsViewModelMapper.toTeacherListItem(profile),
      );

      this.listItems.set(append ? [...this.listItems(), ...mapped] : mapped);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(error instanceof Error ? error.message : 'Failed to load teachers.');
    }
  }

  async loadMore(filters: TeacherProfileFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, {
      cursor: this.nextCursor(),
      append: true,
      sort: this.listSort(),
    });
  }

  async changeSort(filters: TeacherProfileFilters, sort: SortRequest): Promise<void> {
    await this.loadList(filters, { sort, append: false, cursor: null });
  }

  async moderateProfile(
    teacherId: string,
    action: TeacherProfileModerationAction,
    reason?: string,
    filters?: TeacherProfileFilters,
  ): Promise<void> {
    this.actionLoading.set(true);
    try {
      await this.moderateUseCase.execute(teacherId, action, reason);
      if (filters) {
        await this.loadList(filters);
      }
    } finally {
      this.actionLoading.set(false);
    }
  }
}
