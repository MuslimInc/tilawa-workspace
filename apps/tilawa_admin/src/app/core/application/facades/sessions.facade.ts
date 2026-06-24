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
  SessionTimelineEventVm,
} from '../../data/view-models/quran-sessions.view-model';

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

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<AdminSessionListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);

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
  private activeSessionId: string | null = null;

  private readonly actionLoading = signal(false);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();
  readonly timelineEvents = this.timeline.asReadonly();
  readonly compensationHistory = this.compensations.asReadonly();
  readonly callTrackingSummary = this.callTracking.asReadonly();
  readonly callEvents = this.callEventsItems.asReadonly();
  readonly callEventsLoadState = this.callEventsState.asReadonly();
  readonly canLoadMoreCallEvents = this.callEventsHasMore.asReadonly();
  readonly isActionLoading = this.actionLoading.asReadonly();

  async loadList(
    filters: AdminSessionFilters,
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

      const mapped = page.items.map((item) =>
        QuranSessionsViewModelMapper.toSessionListItem(item),
      );

      this.listItems.set(append ? [...this.listItems(), ...mapped] : mapped);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(
        error instanceof Error ? error.message : 'Failed to load sessions.',
      );
    }
  }

  async loadMore(filters: AdminSessionFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, this.nextCursor(), true);
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
        return;
      }

      this.activeSessionId = session.sessionId;

      // One round-trip for everything tied to the detail view. The call
      // summary is a single aggregated doc and is only read when the booking
      // actually has a session — no read otherwise. Raw events are NOT loaded
      // here; they are fetched lazily on demand.
      const [events, comps, callSummary] = await Promise.all([
        this.timelineUseCase.execute(session.aggregateId),
        this.compensationsUseCase.execute(session.id),
        session.sessionId
          ? this.callSummaryUseCase.execute(session.sessionId)
          : Promise.resolve(null),
      ]);

      this.detailItem.set(QuranSessionsViewModelMapper.toSessionDetail(session));
      this.timeline.set(events.map(QuranSessionsViewModelMapper.toTimelineEvent));
      this.compensations.set(comps.map(QuranSessionsViewModelMapper.toCompensation));
      this.callTracking.set(
        callSummary
          ? QuranSessionsViewModelMapper.toCallTracking(
              callSummary,
              session.callType,
            )
          : null,
      );
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(
        error instanceof Error ? error.message : 'Failed to load session.',
      );
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
      this.callEventsItems.set(
        page.items.map(QuranSessionsViewModelMapper.toCallEvent),
      );
      this.callEventsCursor.set(page.nextCursor);
      this.callEventsHasMore.set(page.hasMore);
      this.callEventsState.set('success');
    } catch (error) {
      this.callEventsState.set('error');
      this.detailError.set(
        error instanceof Error ? error.message : 'Failed to load call events.',
      );
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
      await this.compensationUseCase.execute(
        bookingId,
        compensationType,
        reason,
        amountUsd,
      );
      await this.loadDetail(bookingId);
    });
  }

  async confirmReschedule(
    requestId: string,
    bookingId: string,
    accept: boolean,
  ): Promise<void> {
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
