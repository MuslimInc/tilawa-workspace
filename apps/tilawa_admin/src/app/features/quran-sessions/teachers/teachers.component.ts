import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { TeachersFacade } from '../../../core/application/facades/teachers.facade';
import { TeacherProfileFilters } from '../../../core/domain/entities/teacher-profile.entity';
import { TeacherVerificationStatus } from '../../../core/domain/entities/teacher-profile.entity';
import { TeacherProfileModerationAction } from '../../../core/domain/entities/moderation-action.enum';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { SortableThComponent } from '../../../shared/components/sortable-th/sortable-th.component';
import { TilawaFilterBarComponent } from '../../../shared/components/tilawa-filter-bar/tilawa-filter-bar.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TilawaPaginationComponent } from '../../../shared/components/tilawa-pagination/tilawa-pagination.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaAvatarComponent } from '../../../shared/components/tilawa-avatar/tilawa-avatar.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { SortRequest } from '../../../core/domain/entities/pagination.types';

@Component({
  selector: 'app-teachers',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PageHeaderComponent,
    StatusChipComponent,
    ConfirmDialogComponent,
    SortableThComponent,
    TilawaFilterBarComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TilawaPaginationComponent,
    TilawaButtonComponent,
    TilawaAvatarComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './teachers.component.html',
})
export class TeachersComponent implements OnInit {
  private readonly facade = inject(TeachersFacade);

  readonly items = this.facade.items;
  readonly loadState = this.facade.listLoadState;
  readonly errorMessage = this.facade.listErrorMessage;
  readonly canLoadMore = this.facade.canLoadMore;
  readonly isActionLoading = this.facade.isActionLoading;
  readonly sort = this.facade.sort;

  searchQuery = '';
  activeFilter = '';
  verificationFilter = '';
  languageFilter = '';
  specializationFilter = '';

  confirmOpen = false;
  pendingTeacherId = '';
  pendingAction: TeacherProfileModerationAction | null = null;
  readonly TeacherProfileModerationAction = TeacherProfileModerationAction;

  ngOnInit(): void {
    void this.reload();
  }

  buildFilters(): TeacherProfileFilters {
    return {
      search: this.searchQuery || null,
      countryCode: null,
      cityId: null,
      isActive:
        this.activeFilter === 'true'
          ? true
          : this.activeFilter === 'false'
            ? false
            : null,
      verificationStatus: this.verificationFilter
        ? (this.verificationFilter as TeacherVerificationStatus)
        : null,
      language: this.languageFilter || null,
      specialization: this.specializationFilter || null,
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

  openModeration(
    teacherId: string,
    action: TeacherProfileModerationAction,
  ): void {
    this.pendingTeacherId = teacherId;
    this.pendingAction = action;
    this.confirmOpen = true;
  }

  async onConfirmModeration(): Promise<void> {
    if (!this.pendingTeacherId || !this.pendingAction) {
      return;
    }
    await this.facade.moderateProfile(
      this.pendingTeacherId,
      this.pendingAction,
      undefined,
      this.buildFilters(),
    );
    this.confirmOpen = false;
  }
}
