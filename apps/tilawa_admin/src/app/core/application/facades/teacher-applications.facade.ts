import { Injectable, inject, signal } from '@angular/core';
import { Inject } from '@angular/core';

import { ListTeacherApplicationsUseCase } from '../../domain/usecases/teacher-application.usecases';
import { GetTeacherApplicationUseCase } from '../../domain/usecases/teacher-application.usecases';
import { ReviewTeacherApplicationUseCase } from '../../domain/usecases/review-teacher-application.usecase';
import {
  TEACHER_APPLICATION_DEFAULT_SORT,
  TeacherApplicationFilters,
} from '../../domain/entities/teacher-application.entity';
import { DEFAULT_PAGE_SIZE, SortRequest, sortsEqual } from '../../domain/entities/pagination.types';
import { ApplicationModerationAction } from '../../domain/entities/moderation-action.enum';
import {
  TeacherApplicationDetailVm,
  TeacherApplicationListItemVm,
  QuranSessionsViewModelMapper,
} from '../../data/view-models/quran-sessions.view-model';
import {
  QURAN_SESSIONS_USER_REPOSITORY,
  QuranSessionsUserRepository,
} from '../../domain/repositories/quran-sessions-user.repository';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class TeacherApplicationsFacade {
  private readonly listUseCase = inject(ListTeacherApplicationsUseCase);
  private readonly getUseCase = inject(GetTeacherApplicationUseCase);
  private readonly reviewUseCase = inject(ReviewTeacherApplicationUseCase);

  constructor(
    @Inject(QURAN_SESSIONS_USER_REPOSITORY)
    private readonly userRepository: QuranSessionsUserRepository,
  ) {}

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<TeacherApplicationListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly listSort = signal<SortRequest>(TEACHER_APPLICATION_DEFAULT_SORT);

  private readonly detailState = signal<LoadState>('idle');
  private readonly detailError = signal<string | null>(null);
  private readonly detailItem = signal<TeacherApplicationDetailVm | null>(null);

  private readonly actionLoading = signal(false);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly sort = this.listSort.asReadonly();

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();

  async loadList(
    filters: TeacherApplicationFilters,
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

      const users = await this.userRepository.getByIds(page.items.map((item) => item.userId));

      let mapped = page.items.map((item) =>
        QuranSessionsViewModelMapper.toApplicationListItem(item, users.get(item.userId) ?? null),
      );

      if (filters.search?.trim()) {
        const search = filters.search.trim().toLowerCase();
        mapped = mapped.filter(
          (item) =>
            item.publicDisplayName.toLowerCase().includes(search) ||
            item.accountDisplayName.toLowerCase().includes(search) ||
            item.email.toLowerCase().includes(search) ||
            item.userId.toLowerCase().includes(search) ||
            (item.phoneNumber?.toLowerCase().includes(search) ?? false),
        );
      }

      this.listItems.set(append ? [...this.listItems(), ...mapped] : mapped);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(error instanceof Error ? error.message : 'Failed to load applications.');
    }
  }

  async loadMore(filters: TeacherApplicationFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, {
      cursor: this.nextCursor(),
      append: true,
      sort: this.listSort(),
    });
  }

  async changeSort(filters: TeacherApplicationFilters, sort: SortRequest): Promise<void> {
    await this.loadList(filters, { sort, append: false, cursor: null });
  }

  async loadDetail(id: string): Promise<void> {
    this.detailState.set('loading');
    this.detailError.set(null);

    try {
      const application = await this.getUseCase.execute(id);
      if (!application) {
        this.detailState.set('error');
        this.detailError.set('Application not found.');
        this.detailItem.set(null);
        return;
      }

      const user = await this.userRepository.getById(application.userId);
      this.detailItem.set(QuranSessionsViewModelMapper.toApplicationDetail(application, user));
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(error instanceof Error ? error.message : 'Failed to load application.');
    }
  }

  async review(
    applicationId: string,
    action: ApplicationModerationAction,
    reason?: string,
  ): Promise<void> {
    this.actionLoading.set(true);
    try {
      await this.reviewUseCase.execute(applicationId, action, reason);
      await this.loadDetail(applicationId);
    } finally {
      this.actionLoading.set(false);
    }
  }
}
