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

@Component({
  selector: 'app-teachers',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PageHeaderComponent,
    StatusChipComponent,
    ConfirmDialogComponent,
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
