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
  QuranSessionsViewModelMapper,
  SessionCompensationVm,
  SessionTimelineEventVm,
} from '../../data/view-models/quran-sessions.view-model';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

@Injectable({ providedIn: 'root' })
export class SessionsFacade {
  private readonly listUseCase = inject(ListAdminSessionsUseCase);
  private readonly getUseCase = inject(GetAdminSessionUseCase);
  private readonly timelineUseCase = inject(GetSessionTimelineUseCase);
  private readonly compensationsUseCase = inject(ListSessionCompensationsUseCase);
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

    try {
      const session = await this.getUseCase.execute(bookingId);
      if (!session) {
        this.detailState.set('error');
        this.detailError.set('Session not found.');
        this.detailItem.set(null);
        this.timeline.set([]);
        this.compensations.set([]);
        return;
      }

      const [events, comps] = await Promise.all([
        this.timelineUseCase.execute(session.aggregateId),
        this.compensationsUseCase.execute(session.id),
      ]);

      this.detailItem.set(QuranSessionsViewModelMapper.toSessionDetail(session));
      this.timeline.set(events.map(QuranSessionsViewModelMapper.toTimelineEvent));
      this.compensations.set(comps.map(QuranSessionsViewModelMapper.toCompensation));
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(
        error instanceof Error ? error.message : 'Failed to load session.',
      );
    }
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
