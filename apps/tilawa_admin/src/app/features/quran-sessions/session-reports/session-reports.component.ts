import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { SessionReportsFacade } from '../../../core/application/facades/session-reports.facade';
import { SessionReportFilters } from '../../../core/domain/entities/session-report-summary.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-session-reports',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
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
}
