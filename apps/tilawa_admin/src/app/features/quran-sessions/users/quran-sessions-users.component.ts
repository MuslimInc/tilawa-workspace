import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { QuranSessionsUsersFacade } from '../../../core/application/facades/quran-sessions-users.facade';
import {
  QuranSessionsAccountStatus,
  QuranSessionsUserFilters,
  UserGender,
} from '../../../core/domain/entities/quran-sessions-user.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { RejectReasonDialogComponent } from '../../../shared/components/reject-reason-dialog/reject-reason-dialog.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-quran-sessions-users',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PageHeaderComponent,
    StatusChipComponent,
    RejectReasonDialogComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './quran-sessions-users.component.html',
})
export class QuranSessionsUsersComponent implements OnInit {
  private readonly facade = inject(QuranSessionsUsersFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;
  readonly isActionLoading = this.facade.isActionLoading;

  searchQuery = '';
  countryFilter = '';
  cityFilter = '';
  genderFilter = '';
  profileCompletedFilter = '';
  statusFilter = '';

  suspendOpen = false;
  pendingUserId = '';

  readonly accountStatuses = Object.values(QuranSessionsAccountStatus);
  readonly genders = Object.values(UserGender);

  ngOnInit(): void {
    void this.reload();
  }

  buildFilters(): QuranSessionsUserFilters {
    return {
      search: this.searchQuery || null,
      countryCode: this.countryFilter || null,
      cityId: this.cityFilter || null,
      gender: this.genderFilter ? (this.genderFilter as UserGender) : null,
      profileCompleted:
        this.profileCompletedFilter === 'true'
          ? true
          : this.profileCompletedFilter === 'false'
            ? false
            : null,
      accountStatus: this.statusFilter
        ? (this.statusFilter as QuranSessionsAccountStatus)
        : null,
    };
  }

  reload(): Promise<void> {
    return this.facade.loadList(this.buildFilters());
  }

  loadMore(): Promise<void> {
    return this.facade.loadMore(this.buildFilters());
  }

  openSuspend(userId: string): void {
    this.pendingUserId = userId;
    this.suspendOpen = true;
  }

  async onSuspend(reason: string): Promise<void> {
    await this.facade.suspendUser(this.pendingUserId, reason);
    this.suspendOpen = false;
    await this.reload();
  }
}
