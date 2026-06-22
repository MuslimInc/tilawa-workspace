import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { SessionsFacade } from '../../../core/application/facades/sessions.facade';
import { AdminSessionFilters } from '../../../core/domain/entities/admin-session-summary.entity';
import { SessionLifecycleStatus } from '../../../core/domain/entities/session-lifecycle-status.enum';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';

@Component({
  selector: 'app-sessions',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
  ],
  templateUrl: './sessions.component.html',
})
export class SessionsComponent implements OnInit {
  private readonly facade = inject(SessionsFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;

  statusFilter = '';
  teacherFilter = '';
  studentFilter = '';
  countryFilter = '';
  cityFilter = '';
  searchQuery = '';
  startsFrom = '';
  startsTo = '';

  readonly statusOptions = Object.values(SessionLifecycleStatus).filter(
    (s) => s !== SessionLifecycleStatus.Unknown,
  );

  ngOnInit(): void {
    void this.reload();
  }

  buildFilters(): AdminSessionFilters {
    return {
      status: this.statusFilter
        ? (this.statusFilter as SessionLifecycleStatus)
        : null,
      teacherId: this.teacherFilter || null,
      studentId: this.studentFilter || null,
      countryCode: this.countryFilter || null,
      cityId: this.cityFilter || null,
      search: this.searchQuery || null,
      startsFrom: this.startsFrom ? new Date(this.startsFrom) : null,
      startsTo: this.startsTo ? new Date(this.endsOfDay(this.startsTo)) : null,
    };
  }

  reload(): Promise<void> {
    return this.facade.loadList(this.buildFilters());
  }

  loadMore(): Promise<void> {
    return this.facade.loadMore(this.buildFilters());
  }

  private endsOfDay(dateInput: string): Date {
    const date = new Date(dateInput);
    date.setHours(23, 59, 59, 999);
    return date;
  }
}
