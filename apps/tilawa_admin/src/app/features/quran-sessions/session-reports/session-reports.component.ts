import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { SessionReportsFacade } from '../../../core/application/facades/session-reports.facade';
import { SessionReportFilters } from '../../../core/domain/entities/session-report-summary.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { SortableThComponent } from '../../../shared/components/sortable-th/sortable-th.component';
import { TilawaFilterBarComponent } from '../../../shared/components/tilawa-filter-bar/tilawa-filter-bar.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TilawaPaginationComponent } from '../../../shared/components/tilawa-pagination/tilawa-pagination.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { SortRequest } from '../../../core/domain/entities/pagination.types';

@Component({
  selector: 'app-session-reports',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
    SortableThComponent,
    TilawaFilterBarComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TilawaPaginationComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './session-reports.component.html',
})
export class SessionReportsComponent implements OnInit {
  private readonly facade = inject(SessionReportsFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;
  readonly sort = this.facade.sort;

  statusFilter = '';
  severityFilter = '';
  categoryFilter = '';
  searchQuery = '';

  readonly statusOptions = ['open', 'under_review', 'resolved', 'dismissed'];
  readonly severityOptions = ['high', 'normal'];

  ngOnInit(): void {
    void this.reload();
  }

  buildFilters(): SessionReportFilters {
    return {
      status: this.statusFilter
        ? (this.statusFilter as SessionReportFilters['status'])
        : null,
      severity: this.severityFilter
        ? (this.severityFilter as SessionReportFilters['severity'])
        : null,
      category: this.categoryFilter || null,
      search: this.searchQuery || null,
    };
  }

  reload(): Promise<void> {
    return this.facade.loadList(this.buildFilters());
  }

  loadMore(): Promise<void> {
    return this.facade.loadMore(this.buildFilters());
  }

  onSortChange(sort: SortRequest): void {
    void this.facade.changeSort(this.buildFilters(), sort);
  }
}
