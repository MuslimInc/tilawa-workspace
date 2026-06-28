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
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { RejectReasonDialogComponent } from '../../../shared/components/reject-reason-dialog/reject-reason-dialog.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { SortableThComponent } from '../../../shared/components/sortable-th/sortable-th.component';
import { TilawaFilterBarComponent } from '../../../shared/components/tilawa-filter-bar/tilawa-filter-bar.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TilawaPaginationComponent } from '../../../shared/components/tilawa-pagination/tilawa-pagination.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaAvatarComponent } from '../../../shared/components/tilawa-avatar/tilawa-avatar.component';
import { SortRequest } from '../../../core/domain/entities/pagination.types';

@Component({
  selector: 'app-quran-sessions-users',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PageHeaderComponent,
    StatusChipComponent,
    ConfirmDialogComponent,
    RejectReasonDialogComponent,
    TranslatePipe,
    StatusLabelPipe,
    SortableThComponent,
    TilawaFilterBarComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TilawaPaginationComponent,
    TilawaButtonComponent,
    TilawaAvatarComponent,
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
  readonly sort = this.facade.sort;

  searchQuery = '';
  countryFilter = '';
  cityFilter = '';
  genderFilter = '';
  profileCompletedFilter = '';
  statusFilter = '';

  suspendOpen = false;
  reactivateOpen = false;
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

  onSortChange(sort: SortRequest): void {
    void this.facade.changeSort(this.buildFilters(), sort);
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

  openReactivate(userId: string): void {
    this.pendingUserId = userId;
    this.reactivateOpen = true;
  }

  async onReactivate(): Promise<void> {
    await this.facade.reactivateUser(this.pendingUserId);
    this.reactivateOpen = false;
    await this.reload();
  }

  async cycleTeacherApplyAccess(userId: string, current: boolean | null): Promise<void> {
    this.pendingUserId = userId;
    const next =
      current === null ? true : current === true ? false : null;
    await this.facade.setTeacherApplicationAccess(userId, next);
  }

  teacherApplyAccessLabel(value: boolean | null): string {
    if (value === true) {
      return 'quranSessionsUsers_teacherApplyAllowed';
    }
    if (value === false) {
      return 'quranSessionsUsers_teacherApplyDenied';
    }
    return 'quranSessionsUsers_teacherApplyPolicy';
  }
}
