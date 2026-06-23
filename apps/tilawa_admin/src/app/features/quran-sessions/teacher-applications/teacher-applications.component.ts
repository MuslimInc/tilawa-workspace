import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { TeacherApplicationsFacade } from '../../../core/application/facades/teacher-applications.facade';
import { TeacherApplicationStatus } from '../../../core/domain/entities/teacher-application-status.enum';
import { TeacherApplicationFilters } from '../../../core/domain/entities/teacher-application.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-teacher-applications',
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
  templateUrl: './teacher-applications.component.html',
})
export class TeacherApplicationsComponent implements OnInit {
  private readonly facade = inject(TeacherApplicationsFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;

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
}
