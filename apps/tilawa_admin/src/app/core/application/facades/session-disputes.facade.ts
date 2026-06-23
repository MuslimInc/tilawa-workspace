import { Injectable, inject, signal } from '@angular/core';

import {
  ListSessionDisputesUseCase,
  GetSessionDisputeUseCase,
} from '../../domain/usecases/session-dispute.usecases';
import { SessionDisputeFilters } from '../../domain/entities/session-dispute-summary.entity';
import { SessionReadRepository, SESSION_READ_REPOSITORY } from '../../domain/repositories/session-read.repository';
import {
  QuranSessionsUserRepository,
  QURAN_SESSIONS_USER_REPOSITORY,
} from '../../domain/repositories/quran-sessions-user.repository';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

export interface SessionDisputeListItemVm {
  id: string;
  status: string;
  bookingId: string;
  sessionId: string | null;
  openedByUserId: string;
  openedByRole: string;
  createdAt: Date;
  reasonPreview: string;
}

export interface SessionDisputeDetailVm extends SessionDisputeListItemVm {
  aggregateId: string;
  reason: string;
  resolutionReason: string | null;
  resolvedByUserId: string | null;
  studentId: string | null;
  studentName: string | null;
  teacherId: string | null;
  teacherName: string | null;
  updatedAt: Date | null;
  resolvedAt: Date | null;
}

@Injectable({ providedIn: 'root' })
export class SessionDisputesFacade {
  private readonly listUseCase = inject(ListSessionDisputesUseCase);
  private readonly getUseCase = inject(GetSessionDisputeUseCase);
  private readonly sessionReadRepository = inject(SESSION_READ_REPOSITORY);
  private readonly userRepository = inject(QURAN_SESSIONS_USER_REPOSITORY);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<SessionDisputeListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);

  private readonly detailState = signal<LoadState>('idle');
  private readonly detailError = signal<string | null>(null);
  private readonly detailItem = signal<SessionDisputeDetailVm | null>(null);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();

  async loadList(
    filters: SessionDisputeFilters,
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

      const mapped = page.items.map((item) => this.toListItem(item));
      this.listItems.set(append ? [...this.listItems(), ...mapped] : mapped);
      this.nextCursor.set(page.nextCursor);
      this.hasMore.set(page.hasMore);
      this.listState.set('success');
    } catch (error) {
      this.listState.set('error');
      this.listError.set(
        error instanceof Error ? error.message : 'Failed to load disputes.',
      );
    }
  }

  async loadMore(filters: SessionDisputeFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, this.nextCursor(), true);
  }

  async loadDetail(disputeId: string): Promise<void> {
    this.detailState.set('loading');
    this.detailError.set(null);

    try {
      const dispute = await this.getUseCase.execute(disputeId);
      if (!dispute) {
        this.detailState.set('error');
        this.detailError.set('Dispute not found.');
        this.detailItem.set(null);
        return;
      }

      const session = dispute.bookingId
        ? await this.sessionReadRepository.getById(dispute.bookingId)
        : null;

      const userIds = [session?.studentId, session?.teacherId].filter(
        (id): id is string => Boolean(id),
      );
      const users = userIds.length
        ? await this.userRepository.getByIds(userIds)
        : new Map();

      this.detailItem.set(
        this.toDetail(dispute, session, users),
      );
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(
        error instanceof Error ? error.message : 'Failed to load dispute.',
      );
    }
  }

  private toListItem(
    item: Awaited<
      ReturnType<ListSessionDisputesUseCase['execute']>
    >['items'][number],
  ): SessionDisputeListItemVm {
    return {
      id: item.id,
      status: item.status,
      bookingId: item.bookingId,
      sessionId: item.sessionId,
      openedByUserId: item.openedByUserId,
      openedByRole: item.openedByRole,
      createdAt: item.createdAt,
      reasonPreview:
        item.reason.length > 80
          ? `${item.reason.slice(0, 80)}…`
          : item.reason,
    };
  }

  private toDetail(
    item: NonNullable<Awaited<ReturnType<GetSessionDisputeUseCase['execute']>>>,
    session: Awaited<ReturnType<SessionReadRepository['getById']>>,
    users: Awaited<ReturnType<QuranSessionsUserRepository['getByIds']>>,
  ): SessionDisputeDetailVm {
    const studentId = session?.studentId ?? null;
    const teacherId = session?.teacherId ?? null;

    return {
      ...this.toListItem(item),
      aggregateId: item.aggregateId,
      reason: item.reason,
      resolutionReason: item.resolutionReason,
      resolvedByUserId: item.resolvedByUserId,
      studentId,
      studentName: studentId
        ? (users.get(studentId)?.displayName ?? users.get(studentId)?.email ?? null)
        : null,
      teacherId,
      teacherName: teacherId
        ? (users.get(teacherId)?.displayName ?? users.get(teacherId)?.email ?? null)
        : null,
      updatedAt: item.updatedAt,
      resolvedAt: item.resolvedAt,
    };
  }
}
