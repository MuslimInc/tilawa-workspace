import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { TeacherApplicationsFacade } from '../../../core/application/facades/teacher-applications.facade';
import { TeacherApplicationStatus } from '../../../core/domain/entities/teacher-application-status.enum';
import { TeacherApplicationFilters } from '../../../core/domain/entities/teacher-application.entity';
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
  selector: 'app-teacher-applications',
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
  templateUrl: './teacher-applications.component.html',
})
export class TeacherApplicationsComponent implements OnInit {
  private readonly facade = inject(TeacherApplicationsFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;
  readonly sort = this.facade.sort;

  statusFilter = '';
  searchQuery = '';
  countryFilter = '';
  cityFilter = '';
  specializationFilter = '';

  readonly statusOptions = Object.values(TeacherApplicationStatus).filter(
    (s) => s !== TeacherApplicationStatus.None,
  );

  ngOnInit(): void {
    void this.reload();
  }

  buildFilters(): TeacherApplicationFilters {
    return {
      status: this.statusFilter
        ? (this.statusFilter as TeacherApplicationStatus)
        : null,
      countryCode: this.countryFilter || null,
      cityId: this.cityFilter || null,
      specialization: this.specializationFilter || null,
      search: this.searchQuery || null,
      submittedFrom: null,
      submittedTo: null,
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
