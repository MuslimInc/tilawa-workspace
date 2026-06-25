import { Injectable, inject, signal } from '@angular/core';

import { ListActiveAdminSessionsUseCase } from '../../domain/usecases/active-session.usecases';
import {
  ACTIVE_SESSION_PAGE_SIZE,
  ActiveSessionFilters,
  ActiveSessionOperationalFilter,
  matchesOperationalFilter,
} from '../../domain/entities/active-session.entity';
import {
  CALL_TRACKING_REPOSITORY,
  CallTrackingRepository,
} from '../../domain/repositories/call-tracking.repository';
import {
  TEACHER_PROFILE_REPOSITORY,
  TeacherProfileRepository,
} from '../../domain/repositories/teacher-profile.repository';
import {
  QURAN_SESSIONS_USER_REPOSITORY,
  QuranSessionsUserRepository,
} from '../../domain/repositories/quran-sessions-user.repository';
import {
  ActiveSessionListItemVm,
  ActiveSessionsViewModelMapper,
} from '../../data/view-models/active-sessions.view-model';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class ActiveSessionsFacade {
  private readonly listUseCase = inject(ListActiveAdminSessionsUseCase);
  private readonly callTrackingRepository = inject(CALL_TRACKING_REPOSITORY);
  private readonly teacherRepository = inject(TEACHER_PROFILE_REPOSITORY);
  private readonly userRepository = inject(QURAN_SESSIONS_USER_REPOSITORY);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<ActiveSessionListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly operationalFilter = signal<ActiveSessionOperationalFilter>(
    ActiveSessionOperationalFilter.All,
  );

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly filter = this.operationalFilter.asReadonly();

  async loadList(
    options?: {
      filter?: ActiveSessionOperationalFilter;
      cursor?: string | null;
      append?: boolean;
    },
  ): Promise<void> {
    const filter = options?.filter ?? this.operationalFilter();
    const append = options?.append === true;
    const cursor = append ? (options?.cursor ?? this.nextCursor()) : null;

    this.operationalFilter.set(filter);
    this.listState.set('loading');
    this.listError.set(null);

    try {
      const now = new Date();
      const page = await this.listUseCase.execute(
        { operationalFilter: filter, now },
        { pageSize: ACTIVE_SESSION_PAGE_SIZE, cursor },
      );

      const sessionIds = page.items
        .map((item) => item.sessionId)
        .filter((id): id is string => Boolean(id));
      const teacherIds = [...new Set(page.items.map((item) => item.teacherId))];
      const studentIds = [...new Set(page.items.map((item) => item.studentId))];

      const [summaries, teachers] = await Promise.all([
        this.callTrackingRepository.getSummariesBySessionIds(sessionIds),
        this.teacherRepository.getByIds(teacherIds),
      ]);

      const userIds = [
        ...studentIds,
        ...[...teachers.values()].map((profile) => profile.userId),
      ];
      const users = userIds.length
        ? await this.userRepository.getByIds(userIds)
        : new Map();

      const mapped = page.items
        .map((session) => {
          const teacher = teachers.get(session.teacherId) ?? null;
          return ActiveSessionsViewModelMapper.toListItem({
            session,
            summary: session.sessionId
              ? (summaries.get(session.sessionId) ?? null)
              : null,
            teacher,
            teacherUser: teacher
              ? (users.get(teacher.userId) ?? null)
              : null,
            student: users.get(session.studentId) ?? null,
            now,
          });
        })
        .filter((row) =>
          matchesOperationalFilter(row.operationalStatus, filter, {
            teacherLate: row.teacherLate,
            studentLate: row.studentLate,
          }),
        );

      this.listItems.set(append ? [...this.listItems(), ...mapped] : mapped);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(
        error instanceof Error
          ? error.message
          : 'Failed to load active sessions.',
      );
    }
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList({
      filter: this.operationalFilter(),
      cursor: this.nextCursor(),
      append: true,
    });
  }

  async changeFilter(filter: ActiveSessionOperationalFilter): Promise<void> {
    await this.loadList({ filter, append: false, cursor: null });
  }
}
