import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { SessionDisputesFacade } from '../../../core/application/facades/session-disputes.facade';
import { SessionDisputeFilters } from '../../../core/domain/entities/session-dispute-summary.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { SortableThComponent } from '../../../shared/components/sortable-th/sortable-th.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { SortRequest } from '../../../core/domain/entities/pagination.types';

@Component({
  selector: 'app-session-disputes',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
    SortableThComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './session-disputes.component.html',
})
export class SessionDisputesComponent implements OnInit {
  private readonly facade = inject(SessionDisputesFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;
  readonly sort = this.facade.sort;

  statusFilter = '';
  searchQuery = '';

  readonly statusOptions = [
    'opened',
    'under_review',
    'resolved_favor_student',
    'resolved_favor_teacher',
    'resolved_with_compensation',
    'rejected',
    'closed',
  ];

  ngOnInit(): void {
    void this.reload();
  }

  buildFilters(): SessionDisputeFilters {
    return {
      status: this.statusFilter
        ? (this.statusFilter as SessionDisputeFilters['status'])
        : null,
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
