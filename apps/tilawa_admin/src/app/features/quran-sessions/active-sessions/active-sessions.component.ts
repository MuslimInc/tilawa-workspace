import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ActiveSessionsFacade } from '../../../core/application/facades/active-sessions.facade';
import { ActiveSessionOperationalFilter } from '../../../core/domain/entities/active-session.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TilawaPaginationComponent } from '../../../shared/components/tilawa-pagination/tilawa-pagination.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-active-sessions',
  standalone: true,
  imports: [
    CommonModule,
    PageHeaderComponent,
    StatusChipComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TilawaPaginationComponent,
    TilawaButtonComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './active-sessions.component.html',
})
export class ActiveSessionsComponent implements OnInit {
  private readonly facade = inject(ActiveSessionsFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;
  readonly filter = this.facade.filter;

  readonly filterOptions: readonly {
    value: ActiveSessionOperationalFilter;
    labelKey: string;
  }[] = [
    { value: ActiveSessionOperationalFilter.All, labelKey: 'activeSessions_filter_all' },
    {
      value: ActiveSessionOperationalFilter.LiveNow,
      labelKey: 'activeSessions_filter_liveNow',
    },
    {
      value: ActiveSessionOperationalFilter.WaitingForTeacher,
      labelKey: 'activeSessions_filter_waitingTeacher',
    },
    {
      value: ActiveSessionOperationalFilter.WaitingForStudent,
      labelKey: 'activeSessions_filter_waitingStudent',
    },
    {
      value: ActiveSessionOperationalFilter.LateNoShow,
      labelKey: 'activeSessions_filter_lateNoShow',
    },
    {
      value: ActiveSessionOperationalFilter.Interrupted,
      labelKey: 'activeSessions_filter_interrupted',
    },
    {
      value: ActiveSessionOperationalFilter.RecentlyEnded,
      labelKey: 'activeSessions_filter_recentlyEnded',
    },
  ];

  ngOnInit(): void {
    void this.reload();
  }

  reload(): Promise<void> {
    return this.facade.loadList({ filter: this.filter() });
  }

  loadMore(): Promise<void> {
    return this.facade.loadMore();
  }

  setFilter(filter: ActiveSessionOperationalFilter): void {
    void this.facade.changeFilter(filter);
  }

  isFilterActive(filter: ActiveSessionOperationalFilter): boolean {
    return this.filter() === filter;
  }
}
