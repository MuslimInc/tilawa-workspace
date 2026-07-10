import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { SessionReportsFacade } from '../../../core/application/facades/session-reports.facade';
import { SessionReportResolution } from '../../../core/domain/entities/session-report-summary.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { RejectReasonDialogComponent } from '../../../shared/components/reject-reason-dialog/reject-reason-dialog.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

type TerminalResolution = Exclude<SessionReportResolution, 'under_review'>;

@Component({
  selector: 'app-session-report-detail',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
    ConfirmDialogComponent,
    RejectReasonDialogComponent,
    TilawaButtonComponent,
    TilawaCardComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './session-report-detail.component.html',
})
export class SessionReportDetailComponent implements OnInit {
  private readonly facade = inject(SessionReportsFacade);
  private readonly route = inject(ActivatedRoute);

  readonly detail = this.facade.detail;
  readonly loadState = this.facade.detailLoadState;
  readonly errorMessage = this.facade.detailErrorMessage;
  readonly isActionLoading = this.facade.isActionLoading;
  readonly actionError = this.facade.actionErrorMessage;

  readonly confirmUnderReviewOpen = signal(false);
  readonly reasonOpen = signal(false);
  readonly pendingResolution = signal<TerminalResolution | null>(null);

  private reportId = '';

  ngOnInit(): void {
    this.reportId = this.route.snapshot.paramMap.get('id') ?? '';
    if (this.reportId) {
      void this.facade.loadDetail(this.reportId);
    }
  }

  /** Terminal reports are read-only; the server owns their resolution record. */
  isTerminal(status: string): boolean {
    return status === 'resolved' || status === 'dismissed';
  }

  openUnderReview(): void {
    this.facade.clearActionError();
    this.confirmUnderReviewOpen.set(true);
  }

  openTerminal(resolution: TerminalResolution): void {
    this.facade.clearActionError();
    this.pendingResolution.set(resolution);
    this.reasonOpen.set(true);
  }

  async onConfirmUnderReview(): Promise<void> {
    if (this.isActionLoading()) {
      return;
    }
    const succeeded = await this.facade.resolveReport(this.reportId, 'under_review');
    if (succeeded) {
      this.confirmUnderReviewOpen.set(false);
    }
  }

  async onSubmitReason(reason: string): Promise<void> {
    const resolution = this.pendingResolution();
    if (!resolution || this.isActionLoading()) {
      return;
    }
    const succeeded = await this.facade.resolveReport(this.reportId, resolution, reason);
    if (succeeded) {
      this.reasonOpen.set(false);
      this.pendingResolution.set(null);
    }
  }

  closeDialogs(): void {
    this.confirmUnderReviewOpen.set(false);
    this.reasonOpen.set(false);
    this.pendingResolution.set(null);
  }
}
