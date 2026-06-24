import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { SessionsFacade } from '../../../core/application/facades/sessions.facade';
import {
  NoShowClassification,
  SessionCompensationType,
} from '../../../core/domain/entities/session-moderation.types';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { RejectReasonDialogComponent } from '../../../shared/components/reject-reason-dialog/reject-reason-dialog.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';

type PendingAction =
  | 'cancel'
  | 'noShow'
  | 'complete'
  | 'compensation'
  | 'refund';

@Component({
  selector: 'app-session-detail',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
    ConfirmDialogComponent,
    RejectReasonDialogComponent,
    TranslatePipe,
    StatusLabelPipe,
    TilawaButtonComponent,
    TilawaCardComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
  ],
  templateUrl: './session-detail.component.html',
})
export class SessionDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly facade = inject(SessionsFacade);

  readonly detail = this.facade.detail;
  readonly loadState = this.facade.detailLoadState;
  readonly errorMessage = this.facade.detailErrorMessage;
  readonly timelineEvents = this.facade.timelineEvents;
  readonly compensationHistory = this.facade.compensationHistory;
  readonly callTracking = this.facade.callTrackingSummary;
  readonly callEvents = this.facade.callEvents;
  readonly callEventsLoadState = this.facade.callEventsLoadState;
  readonly canLoadMoreCallEvents = this.facade.canLoadMoreCallEvents;
  readonly isActionLoading = this.facade.isActionLoading;

  readonly eventsPanelOpen = signal(false);
  readonly confirmOpen = signal(false);
  readonly reasonOpen = signal(false);
  readonly pendingAction = signal<PendingAction | null>(null);
  readonly actionError = signal<string | null>(null);

  noShowClassification: NoShowClassification = 'teacher_no_show';
  compensationType: SessionCompensationType = 'restore_credit';
  compensationAmount = '';
  rescheduleRequestId = '';

  readonly noShowOptions: NoShowClassification[] = [
    'teacher_no_show',
    'student_no_show',
    'both_no_show',
  ];

  readonly compensationTypes: SessionCompensationType[] = [
    'restore_credit',
    'wallet_credit',
    'replacement_session',
    'extend_subscription',
    'manual_review',
  ];

  private bookingId = '';

  ngOnInit(): void {
    this.bookingId = this.route.snapshot.paramMap.get('id') ?? '';
    if (this.bookingId) {
      void this.facade.loadDetail(this.bookingId);
    }
  }

  /** Opens the raw-events panel, triggering a one-time lazy load on first open. */
  toggleEventsPanel(): void {
    const opening = !this.eventsPanelOpen();
    this.eventsPanelOpen.set(opening);
    if (opening) {
      void this.facade.loadCallEvents();
    }
  }

  loadMoreCallEvents(): void {
    void this.facade.loadMoreCallEvents();
  }

  openCancel(): void {
    this.pendingAction.set('cancel');
    this.reasonOpen.set(true);
  }

  openNoShow(): void {
    this.pendingAction.set('noShow');
    this.reasonOpen.set(true);
  }

  openComplete(): void {
    this.pendingAction.set('complete');
    this.confirmOpen.set(true);
  }

  openCompensation(): void {
    this.pendingAction.set('compensation');
    this.reasonOpen.set(true);
  }

  openRefund(): void {
    this.pendingAction.set('refund');
    this.reasonOpen.set(true);
  }

  async onConfirmComplete(): Promise<void> {
    const session = this.detail();
    if (!session?.sessionId) {
      this.actionError.set('Session id missing on booking.');
      this.confirmOpen.set(false);
      return;
    }
    await this.run(async () => {
      await this.facade.completeSession(session.sessionId!, this.bookingId);
    });
    this.confirmOpen.set(false);
  }

  async onSubmitReason(reason: string): Promise<void> {
    const action = this.pendingAction();
    const session = this.detail();
    if (!action || !session) {
      return;
    }

    await this.run(async () => {
      switch (action) {
        case 'cancel':
          await this.facade.cancelSession(this.bookingId, reason);
          break;
        case 'noShow':
          if (!session.sessionId) {
            throw new Error('Session id missing on booking.');
          }
          await this.facade.markNoShow(
            session.sessionId,
            this.bookingId,
            this.noShowClassification,
          );
          break;
        case 'compensation': {
          const amount = this.compensationAmount.trim()
            ? Number(this.compensationAmount)
            : undefined;
          await this.facade.issueCompensation(
            this.bookingId,
            this.compensationType,
            reason,
            Number.isFinite(amount) ? amount : undefined,
          );
          break;
        }
        case 'refund':
          await this.facade.approveRefund(this.bookingId, reason);
          break;
      }
    });
    this.reasonOpen.set(false);
  }

  async onConfirmReschedule(accept: boolean): Promise<void> {
    if (!this.rescheduleRequestId.trim()) {
      this.actionError.set('Reschedule request id is required.');
      return;
    }
    await this.run(async () => {
      await this.facade.confirmReschedule(
        this.rescheduleRequestId.trim(),
        this.bookingId,
        accept,
      );
    });
  }

  private async run(action: () => Promise<void>): Promise<void> {
    this.actionError.set(null);
    try {
      await action();
    } catch (error) {
      this.actionError.set(
        error instanceof Error ? error.message : 'Action failed.',
      );
    }
  }
}
