import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { TeacherApplicationsFacade } from '../../../core/application/facades/teacher-applications.facade';
import { ApplicationModerationAction } from '../../../core/domain/entities/moderation-action.enum';
import { TeacherApplicationDetailVm } from '../../../core/data/view-models/quran-sessions.view-model';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { RejectReasonDialogComponent } from '../../../shared/components/reject-reason-dialog/reject-reason-dialog.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { TilawaAvatarComponent } from '../../../shared/components/tilawa-avatar/tilawa-avatar.component';
import { resolveDetailAvatarDisplayName } from '../../../shared/utils/avatar.util';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';

@Component({
  selector: 'app-teacher-application-detail',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
    ConfirmDialogComponent,
    RejectReasonDialogComponent,
    TranslatePipe,
    StatusLabelPipe,
    TilawaAvatarComponent,
    TilawaButtonComponent,
    TilawaCardComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
  ],
  templateUrl: './teacher-application-detail.component.html',
})
export class TeacherApplicationDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly facade = inject(TeacherApplicationsFacade);

  readonly detail = this.facade.detail;
  readonly loadState = this.facade.detailLoadState;
  readonly errorMessage = this.facade.detailErrorMessage;
  readonly isActionLoading = this.facade.isActionLoading;

  readonly confirmOpen = signal(false);
  readonly rejectOpen = signal(false);
  readonly pendingAction = signal<ApplicationModerationAction | null>(null);
  readonly actionError = signal<string | null>(null);

  private applicationId = '';

  ngOnInit(): void {
    this.applicationId = this.route.snapshot.paramMap.get('id') ?? '';
    if (this.applicationId) {
      void this.facade.loadDetail(this.applicationId);
    }
  }

  /** Skips em-dash placeholders so avatar initials resolve from account name or email. */
  avatarDisplayName(app: TeacherApplicationDetailVm): string {
    return resolveDetailAvatarDisplayName(app.publicDisplayName, app.accountDisplayName, app.email);
  }

  openApprove(): void {
    if (this.isActionLoading()) {
      return;
    }
    this.pendingAction.set(ApplicationModerationAction.Approve);
    this.confirmOpen.set(true);
  }

  openReject(): void {
    if (this.isActionLoading()) {
      return;
    }
    this.pendingAction.set(ApplicationModerationAction.Reject);
    this.rejectOpen.set(true);
  }

  openSuspend(): void {
    if (this.isActionLoading()) {
      return;
    }
    this.pendingAction.set(ApplicationModerationAction.Suspend);
    this.rejectOpen.set(true);
  }

  openRevoke(): void {
    if (this.isActionLoading()) {
      return;
    }
    this.pendingAction.set(ApplicationModerationAction.Revoke);
    this.rejectOpen.set(true);
  }

  async onConfirmApprove(): Promise<void> {
    await this.runAction(ApplicationModerationAction.Approve);
    this.confirmOpen.set(false);
  }

  async onSubmitReason(reason: string): Promise<void> {
    const action = this.pendingAction();
    if (!action || action === ApplicationModerationAction.Approve) {
      return;
    }
    await this.runAction(action, reason);
    this.rejectOpen.set(false);
  }

  private async runAction(action: ApplicationModerationAction, reason?: string): Promise<void> {
    this.actionError.set(null);
    try {
      await this.facade.review(this.applicationId, action, reason);
    } catch (error) {
      this.actionError.set(error instanceof Error ? error.message : 'Action failed.');
    }
  }
}
