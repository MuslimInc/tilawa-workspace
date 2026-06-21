import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { TeacherApplicationsFacade } from '../../../core/application/facades/teacher-applications.facade';
import { ApplicationModerationAction } from '../../../core/domain/entities/moderation-action.enum';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { RejectReasonDialogComponent } from '../../../shared/components/reject-reason-dialog/reject-reason-dialog.component';

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

  openApprove(): void {
    this.pendingAction.set(ApplicationModerationAction.Approve);
    this.confirmOpen.set(true);
  }

  openReject(): void {
    this.pendingAction.set(ApplicationModerationAction.Reject);
    this.rejectOpen.set(true);
  }

  openSuspend(): void {
    this.pendingAction.set(ApplicationModerationAction.Suspend);
    this.rejectOpen.set(true);
  }

  openRevoke(): void {
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

  private async runAction(
    action: ApplicationModerationAction,
    reason?: string,
  ): Promise<void> {
    this.actionError.set(null);
    try {
      await this.facade.review(this.applicationId, action, reason);
    } catch (error) {
      this.actionError.set(
        error instanceof Error ? error.message : 'Action failed.',
      );
    }
  }
}
