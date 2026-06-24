import { Injectable, inject, signal } from '@angular/core';

import {
  ListSessionReportsUseCase,
  GetSessionReportUseCase,
} from '../../domain/usecases/session-report.usecases';
import { SessionReportFilters } from '../../domain/entities/session-report-summary.entity';
import { SESSION_REPORT_DEFAULT_SORT } from '../../domain/entities/session-report-summary.entity';
import {
  DEFAULT_PAGE_SIZE,
  SortRequest,
  sortsEqual,
} from '../../domain/entities/pagination.types';

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
  updatedAt: Date | null;
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
  private readonly listSort = signal<SortRequest>(SESSION_REPORT_DEFAULT_SORT);

  private readonly detailState = signal<LoadState>('idle');
  private readonly detailError = signal<string | null>(null);
  private readonly detailItem = signal<SessionReportDetailVm | null>(null);

  readonly items = this.listItems.asReadonly();
  readonly listLoadState = this.listState.asReadonly();
  readonly listErrorMessage = this.listError.asReadonly();
  readonly canLoadMore = this.hasMore.asReadonly();
  readonly sort = this.listSort.asReadonly();

  readonly detail = this.detailItem.asReadonly();
  readonly detailLoadState = this.detailState.asReadonly();
  readonly detailErrorMessage = this.detailError.asReadonly();

  async loadList(
    filters: SessionReportFilters,
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
    await this.loadList(filters, {
      cursor: this.nextCursor(),
      append: true,
      sort: this.listSort(),
    });
  }

  async changeSort(
    filters: SessionReportFilters,
    sort: SortRequest,
  ): Promise<void> {
    await this.loadList(filters, { sort, append: false, cursor: null });
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
      updatedAt: item.updatedAt,
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
