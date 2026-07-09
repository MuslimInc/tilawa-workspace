import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { SessionDisputesFacade } from '../../../core/application/facades/session-disputes.facade';
import { DisputeResolution } from '../../../core/domain/entities/session-moderation.types';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { RejectReasonDialogComponent } from '../../../shared/components/reject-reason-dialog/reject-reason-dialog.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

const DISPUTE_OPEN_STATUSES = ['opened', 'under_review'];

@Component({
  selector: 'app-session-dispute-detail',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
    RejectReasonDialogComponent,
    TilawaButtonComponent,
    TilawaCardComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './session-dispute-detail.component.html',
})
export class SessionDisputeDetailComponent implements OnInit {
  private readonly facade = inject(SessionDisputesFacade);
  private readonly route = inject(ActivatedRoute);

  readonly detail = this.facade.detail;
  readonly loadState = this.facade.detailLoadState;
  readonly errorMessage = this.facade.detailErrorMessage;
  readonly isActionLoading = this.facade.isActionLoading;
  readonly actionError = this.facade.actionErrorMessage;

  readonly reasonOpen = signal(false);

  /** The server owns lifecycle/refund/compensation effects for each outcome. */
  readonly resolutionOptions: DisputeResolution[] = [
    'favor_student',
    'favor_teacher',
    'with_compensation',
    'rejected',
    'closed',
  ];

  selectedResolution: DisputeResolution = 'closed';

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      void this.facade.loadDetail(id);
    }
  }

  /** Resolved/rejected/closed disputes are read-only; only open ones accept actions. */
  isOpenForResolution(status: string): boolean {
    return DISPUTE_OPEN_STATUSES.includes(status);
  }

  outcomeLabelKey(resolution: DisputeResolution): string {
    return DISPUTE_OUTCOME_LABEL_KEYS[resolution];
  }

  effectCopyKey(resolution: DisputeResolution): string {
    return DISPUTE_EFFECT_COPY_KEYS[resolution];
  }

  openResolve(): void {
    this.facade.clearActionError();
    this.reasonOpen.set(true);
  }

  async onSubmitReason(reason: string): Promise<void> {
    const dispute = this.detail();
    if (!dispute || this.isActionLoading()) {
      return;
    }
    const succeeded = await this.facade.resolveDispute(
      dispute.bookingId,
      dispute.id,
      this.selectedResolution,
      reason,
    );
    if (succeeded) {
      this.reasonOpen.set(false);
    }
  }

  closeDialog(): void {
    this.reasonOpen.set(false);
  }
}

const DISPUTE_OUTCOME_LABEL_KEYS: Record<DisputeResolution, string> = {
  favor_student: 'disputes_outcomeFavorStudent',
  favor_teacher: 'disputes_outcomeFavorTeacher',
  with_compensation: 'disputes_outcomeWithCompensation',
  rejected: 'disputes_outcomeRejected',
  closed: 'disputes_outcomeClosed',
};

const DISPUTE_EFFECT_COPY_KEYS: Record<DisputeResolution, string> = {
  favor_student: 'disputes_effectFavorStudent',
  favor_teacher: 'disputes_effectFavorTeacher',
  with_compensation: 'disputes_effectWithCompensation',
  rejected: 'disputes_effectRejected',
  closed: 'disputes_effectClosed',
};
