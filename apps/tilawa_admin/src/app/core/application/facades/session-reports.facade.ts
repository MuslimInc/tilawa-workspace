import { Injectable, inject, signal } from '@angular/core';

import {
  ListSessionReportsUseCase,
  GetSessionReportUseCase,
} from '../../domain/usecases/session-report.usecases';
import { SessionReportFilters } from '../../domain/entities/session-report-summary.entity';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

export interface SessionReportListItemVm {
  id: string;
  category: string;
  severity: string;
  status: string;
  reporterUserId: string;
  reportedUserId: string | null;
  bookingId: string | null;
  createdAt: Date;
  descriptionPreview: string;
}

export interface SessionReportDetailVm extends SessionReportListItemVm {
  sessionId: string | null;
  reporterRole: string;
  description: string;
  updatedAt: Date | null;
}

@Injectable({ providedIn: 'root' })
export class SessionReportsFacade {
  private readonly listUseCase = inject(ListSessionReportsUseCase);
  private readonly getUseCase = inject(GetSessionReportUseCase);

  private readonly listState = signal<LoadState>('idle');
  private readonly listError = signal<string | null>(null);
  private readonly listItems = signal<SessionReportListItemVm[]>([]);
  private readonly nextCursor = signal<string | null>(null);
  private readonly hasMore = signal(false);

  private readonly detailState = signal<LoadState>('idle');
  private readonly detailError = signal<string | null>(null);
  private readonly detailItem = signal<SessionReportDetailVm | null>(null);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();

  async loadList(
    filters: SessionReportFilters,
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
        error instanceof Error ? error.message : 'Failed to load reports.',
      );
    }
  }

  async loadMore(filters: SessionReportFilters): Promise<void> {
    if (!this.hasMore() || !this.nextCursor()) {
      return;
    }
    await this.loadList(filters, this.nextCursor(), true);
  }

  async loadDetail(reportId: string): Promise<void> {
    this.detailState.set('loading');
    this.detailError.set(null);

    try {
      const report = await this.getUseCase.execute(reportId);
      if (!report) {
        this.detailState.set('error');
        this.detailError.set('Report not found.');
        this.detailItem.set(null);
        return;
      }

      this.detailItem.set(this.toDetail(report));
      this.detailState.set('success');
    } catch (error) {
      this.detailState.set('error');
      this.detailError.set(
        error instanceof Error ? error.message : 'Failed to load report.',
      );
    }
  }

  private toListItem(
    item: Awaited<ReturnType<ListSessionReportsUseCase['execute']>>['items'][number],
  ): SessionReportListItemVm {
    return {
      id: item.id,
      category: item.category,
      severity: item.severity,
      status: item.status,
      reporterUserId: item.reporterUserId,
      reportedUserId: item.reportedUserId,
      bookingId: item.bookingId,
      createdAt: item.createdAt,
      descriptionPreview:
        item.description.length > 80
          ? `${item.description.slice(0, 80)}…`
          : item.description,
    };
  }

  private toDetail(
    item: NonNullable<Awaited<ReturnType<GetSessionReportUseCase['execute']>>>,
  ): SessionReportDetailVm {
    return {
      ...this.toListItem(item),
      sessionId: item.sessionId,
      reporterRole: item.reporterRole,
      description: item.description,
      updatedAt: item.updatedAt,
    };
  }
}
