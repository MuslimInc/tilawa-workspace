import { Injectable, inject, signal } from '@angular/core';

import {
  ListAdminSessionsUseCase,
  GetAdminSessionUseCase,
} from '../../domain/usecases/session.usecases';
import {
  GetSessionTimelineUseCase,
  ListSessionCompensationsUseCase,
} from '../../domain/usecases/session-audit.usecases';
import {
  GetCallTrackingSummaryUseCase,
  ListCallEventsUseCase,
} from '../../domain/usecases/call-tracking.usecases';
import {
  CancelSessionUseCase,
  MarkSessionNoShowUseCase,
  CompleteSessionUseCase,
  IssueSessionCompensationUseCase,
  ConfirmSessionRescheduleUseCase,
  ApproveSessionRefundUseCase,
} from '../../domain/usecases/session-moderation.usecases';
import { AdminSessionFilters } from '../../domain/entities/admin-session-summary.entity';
import { ADMIN_SESSION_DEFAULT_SORT } from '../../domain/entities/admin-session-summary.entity';
import { DEFAULT_PAGE_SIZE, SortRequest, sortsEqual } from '../../domain/entities/pagination.types';
import {
  NoShowClassification,
  SessionCompensationType,
} from '../../domain/entities/session-moderation.types';
import {
  AdminSessionDetailVm,
  AdminSessionListItemVm,
  CallEventVm,
  CallTrackingVm,
  QuranSessionsViewModelMapper,
  SessionCompensationVm,
  SessionParticipantsVm,
  SessionTimelineEventVm,
} from '../../data/view-models/quran-sessions.view-model';
import {
  TEACHER_PROFILE_REPOSITORY,
  TeacherProfileRepository,
} from '../../domain/repositories/teacher-profile.repository';
import {
  QURAN_SESSIONS_USER_REPOSITORY,
  QuranSessionsUserRepository,
} from '../../domain/repositories/quran-sessions-user.repository';

const CALL_EVENTS_PAGE_SIZE = 20;

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class SessionsFacade {
  private readonly listUseCase = inject(ListAdminSessionsUseCase);
  private readonly getUseCase = inject(GetAdminSessionUseCase);
  private readonly timelineUseCase = inject(GetSessionTimelineUseCase);
  private readonly compensationsUseCase = inject(ListSessionCompensationsUseCase);
  private readonly callSummaryUseCase = inject(GetCallTrackingSummaryUseCase);
  private readonly callEventsUseCase = inject(ListCallEventsUseCase);
  private readonly cancelUseCase = inject(CancelSessionUseCase);
  private readonly noShowUseCase = inject(MarkSessionNoShowUseCase);
  private readonly completeUseCase = inject(CompleteSessionUseCase);
  private readonly compensationUseCase = inject(IssueSessionCompensationUseCase);
  private readonly rescheduleUseCase = inject(ConfirmSessionRescheduleUseCase);
  private readonly refundUseCase = inject(ApproveSessionRefundUseCase);
  private readonly teacherProfileRepository = inject(TEACHER_PROFILE_REPOSITORY);
  private readonly userRepository = inject(QURAN_SESSIONS_USER_REPOSITORY);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<AdminSessionListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);
  private readonly listSort = signal<SortRequest>(ADMIN_SESSION_DEFAULT_SORT);

  private readonly detailState = signal<LoadState>('idle');
  private readonly detailError = signal<string | null>(null);
  private readonly detailItem = signal<AdminSessionDetailVm | null>(null);
  private readonly timeline = signal<SessionTimelineEventVm[]>([]);
  private readonly compensations = signal<SessionCompensationVm[]>([]);

  private readonly callTracking = signal<CallTrackingVm | null>(null);
  private readonly callEventsItems = signal<CallEventVm[]>([]);
  private readonly callEventsState = signal<LoadState>('idle');
  private readonly callEventsCursor = signal<string | null>(null);
  private readonly callEventsHasMore = signal(false);
  private readonly participantsState = signal<SessionParticipantsVm | null>(null);
  private readonly participantsLoading = signal(false);
  private activeSessionId: string | null = null;

  private readonly actionLoading = signal(false);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly sort = this.listSort.asReadonly();

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();
  readonly timelineEvents = this.timeline.asReadonly();
  readonly compensationHistory = this.compensations.asReadonly();
  readonly callTrackingSummary = this.callTracking.asReadonly();
  readonly callEvents = this.callEventsItems.asReadonly();
  readonly callEventsLoadState = this.callEventsState.asReadonly();
  readonly canLoadMoreCallEvents = this.callEventsHasMore.asReadonly();
  readonly sessionParticipants = this.participantsState.asReadonly();
  readonly isParticipantsLoading = this.participantsLoading.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();

  async loadList(
    filters: AdminSessionFilters,
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

      const mapped = page.items.map((item) => QuranSessionsViewModelMapper.toSessionListItem(item));

      this.listItems.set(append ? [...this.listItems(), ...mapped] : mapped);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(error instanceof Error ? error.message : 'Failed to load sessions.');
    }
  }

  async loadMore(filters: AdminSessionFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, {
      cursor: this.nextCursor(),
      append: true,
      sort: this.listSort(),
    });
  }

  async changeSort(filters: AdminSessionFilters, sort: SortRequest): Promise<void> {
    await this.loadList(filters, { sort, append: false, cursor: null });
  }

  async loadDetail(bookingId: string): Promise<void> {
    this.detailState.set('loading');
    this.detailError.set(null);
    this.resetCallEvents();

    try {
      const session = await this.getUseCase.execute(bookingId);
      if (!session) {
        this.detailState.set('error');
        this.detailError.set('Session not found.');
        this.detailItem.set(null);
        this.timeline.set([]);
        this.compensations.set([]);
        this.callTracking.set(null);
        this.participantsState.set(null);
        return;
      }

      this.activeSessionId = session.sessionId;

      // Render critical session metadata immediately without blocking.
      this.detailItem.set(QuranSessionsViewModelMapper.toSessionDetail(session));
      this.detailState.set('success');

      // Phase 2 — secondary (non-blocking): timeline, compensations, call tracking, and participants.
      this.participantsLoading.set(true);

      this.timelineUseCase.execute(session.aggregateId)
        .then(events => this.timeline.set(events.map(QuranSessionsViewModelMapper.toTimelineEvent)))
        .catch(error => console.error('Failed to load timeline:', error));

      this.compensationsUseCase.execute(session.id)
        .then(comps => this.compensations.set(comps.map(QuranSessionsViewModelMapper.toCompensation)))
        .catch(error => console.error('Failed to load compensations:', error));

      const callSummaryPromise = session.sessionId
        ? this.callSummaryUseCase.execute(session.sessionId)
        : Promise.resolve(null);

      const teacherProfilePromise = this.teacherProfileRepository.getById(session.teacherId);

      const studentUserPromise = session.studentId
        ? this.userRepository.getById(session.studentId)
        : Promise.resolve(null);

      const teacherUserPromise = teacherProfilePromise.then((profile) =>
        profile?.userId ? this.userRepository.getById(profile.userId) : Promise.resolve(null),
      );

      Promise.all([
        callSummaryPromise,
        teacherProfilePromise,
        studentUserPromise,
        teacherUserPromise,
      ])
        .then(([callSummary, teacherProfile, studentUser, teacherUser]) => {
          const callTrackingVm = callSummary
            ? QuranSessionsViewModelMapper.toCallTracking(callSummary, session.callType)
            : null;
          this.callTracking.set(callTrackingVm);

          this.participantsState.set(
            QuranSessionsViewModelMapper.toSessionParticipants({
              session,
              teacherProfile,
              teacherUser,
              studentUser,
              callTracking: callTrackingVm,
            }),
          );
        })
        .catch((error) => console.error('Failed to load call tracking/participants:', error))
        .finally(() => this.participantsLoading.set(false));
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(error instanceof Error ? error.message : 'Failed to load session.');
    }
  }

  /**
   * Lazily loads the first page of raw call events. Idempotent: once loaded it
   * does not re-query on repeated calls (e.g. re-opening the panel), so UI
   * state changes never cost reads. Pass force=true to refresh explicitly.
   */
  async loadCallEvents(force = false): Promise<void> {
    const sessionId = this.activeSessionId;
    if (!sessionId) {
      return;
    }
    if (!force && this.callEventsState() !== 'idle') {
      return;
    }

    this.callEventsState.set('loading');
    try {
      const page = await this.callEventsUseCase.execute(sessionId, {
        pageSize: CALL_EVENTS_PAGE_SIZE,
        cursor: null,
      });
      this.callEventsItems.set(page.items.map(QuranSessionsViewModelMapper.toCallEvent));
      this.callEventsCursor.set(page.nextCursor);
      this.callEventsHasMore.set(page.hasMore);
      this.callEventsState.set('success');
    } catch (error) {
      this.callEventsState.set('error');
      this.detailError.set(error instanceof Error ? error.message : 'Failed to load call events.');
    }
  }

  async loadMoreCallEvents(): Promise<void> {
    const sessionId = this.activeSessionId;
    const cursor = this.callEventsCursor();
    if (!sessionId || !this.callEventsHasMore() || !cursor) {
      return;
    }
    this.callEventsState.set('loading');
    try {
      const page = await this.callEventsUseCase.execute(sessionId, {
        pageSize: CALL_EVENTS_PAGE_SIZE,
        cursor,
      });
      this.callEventsItems.set([
        ...this.callEventsItems(),
        ...page.items.map(QuranSessionsViewModelMapper.toCallEvent),
      ]);
      this.callEventsCursor.set(page.nextCursor);
      this.callEventsHasMore.set(page.hasMore);
      this.callEventsState.set('success');
    } catch (error) {
      this.callEventsState.set('error');
    }
  }

  private resetCallEvents(): void {
    this.callTracking.set(null);
    this.callEventsItems.set([]);
    this.callEventsState.set('idle');
    this.callEventsCursor.set(null);
    this.callEventsHasMore.set(false);
    this.participantsState.set(null);
    this.participantsLoading.set(false);
    this.activeSessionId = null;
  }

  async cancelSession(bookingId: string, reason: string): Promise<void> {
    await this.runAction(async () => {
      await this.cancelUseCase.execute(bookingId, reason);
      await this.loadDetail(bookingId);
    });
  }

  async markNoShow(
    sessionId: string,
    bookingId: string,
    classification: NoShowClassification,
  ): Promise<void> {
    await this.runAction(async () => {
      await this.noShowUseCase.execute(sessionId, classification);
      await this.loadDetail(bookingId);
    });
  }

  async completeSession(sessionId: string, bookingId: string): Promise<void> {
    await this.runAction(async () => {
      await this.completeUseCase.execute(sessionId);
      await this.loadDetail(bookingId);
    });
  }

  async issueCompensation(
    bookingId: string,
    compensationType: SessionCompensationType,
    reason: string,
    amountUsd?: number,
  ): Promise<void> {
    await this.runAction(async () => {
      await this.compensationUseCase.execute(bookingId, compensationType, reason, amountUsd);
      await this.loadDetail(bookingId);
    });
  }

  async confirmReschedule(requestId: string, bookingId: string, accept: boolean): Promise<void> {
    await this.runAction(async () => {
      await this.rescheduleUseCase.execute(requestId, accept);
      await this.loadDetail(bookingId);
    });
  }

  async approveRefund(bookingId: string, reason: string): Promise<void> {
    await this.runAction(async () => {
      await this.refundUseCase.execute(bookingId, reason);
      await this.loadDetail(bookingId);
    });
  }

  private async runAction(action: () => Promise<void>): Promise<void> {
    this.actionLoading.set(true);
    try {
      await action();
    } finally {
      this.actionLoading.set(false);
    }
  }
}
