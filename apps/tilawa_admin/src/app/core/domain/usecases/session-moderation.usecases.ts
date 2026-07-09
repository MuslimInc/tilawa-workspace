import { Inject, Injectable } from '@angular/core';

import {
  NoShowClassification,
  SessionCompensationType,
} from '../entities/session-moderation.types';
import { DisputeResolution } from '../entities/session-moderation.types';
import { SessionReportResolution } from '../entities/session-report-summary.entity';
import {
  SESSION_MODERATION_GATEWAY,
  SessionModerationGateway,
} from '../repositories/session-moderation.gateway';

@Injectable({ providedIn: 'root' })
export class CancelSessionUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(bookingId: string, reason: string): Promise<void> {
    if (!bookingId.trim()) {
      throw new Error('Booking id is required.');
    }
    if (!reason.trim()) {
      throw new Error('A cancellation reason is required.');
    }
    await this.gateway.cancelSessionBooking(bookingId.trim(), reason.trim());
  }
}

@Injectable({ providedIn: 'root' })
export class MarkSessionNoShowUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(sessionId: string, classification: NoShowClassification): Promise<void> {
    if (!sessionId.trim()) {
      throw new Error('Session id is required.');
    }
    await this.gateway.markSessionNoShow(sessionId.trim(), classification);
  }
}

@Injectable({ providedIn: 'root' })
export class CompleteSessionUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(sessionId: string): Promise<void> {
    if (!sessionId.trim()) {
      throw new Error('Session id is required.');
    }
    await this.gateway.completeSession(sessionId.trim());
  }
}

@Injectable({ providedIn: 'root' })
export class IssueSessionCompensationUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(
    bookingId: string,
    compensationType: SessionCompensationType,
    reason: string,
    amountUsd?: number,
  ): Promise<void> {
    if (!bookingId.trim()) {
      throw new Error('Booking id is required.');
    }
    if (!reason.trim()) {
      throw new Error('A compensation reason is required.');
    }
    await this.gateway.issueSessionCompensation(
      bookingId.trim(),
      compensationType,
      reason.trim(),
      amountUsd,
    );
  }
}

@Injectable({ providedIn: 'root' })
export class ConfirmSessionRescheduleUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(requestId: string, accept: boolean): Promise<void> {
    if (!requestId.trim()) {
      throw new Error('Reschedule request id is required.');
    }
    await this.gateway.confirmSessionReschedule(requestId.trim(), accept);
  }
}

@Injectable({ providedIn: 'root' })
export class ApproveSessionRefundUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(bookingId: string, reason: string): Promise<void> {
    if (!bookingId.trim()) {
      throw new Error('Booking id is required.');
    }
    if (!reason.trim()) {
      throw new Error('A refund reason is required.');
    }
    await this.gateway.approveSessionRefund(bookingId.trim(), reason.trim());
  }
}

@Injectable({ providedIn: 'root' })
export class ConfirmManualBookingPaymentUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(bookingId: string, note?: string): Promise<void> {
    if (!bookingId.trim()) {
      throw new Error('Booking id is required.');
    }
    const trimmedNote = note?.trim();
    await this.gateway.confirmManualBookingPayment(
      bookingId.trim(),
      trimmedNote ? trimmedNote : undefined,
    );
  }
}

@Injectable({ providedIn: 'root' })
export class RejectManualBookingPaymentUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(bookingId: string, reason?: string): Promise<void> {
    if (!bookingId.trim()) {
      throw new Error('Booking id is required.');
    }
    const trimmedReason = reason?.trim();
    await this.gateway.rejectManualBookingPayment(
      bookingId.trim(),
      trimmedReason ? trimmedReason : undefined,
    );
  }
}

@Injectable({ providedIn: 'root' })
export class ResolveSessionReportUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(
    reportId: string,
    resolution: SessionReportResolution,
    reason?: string,
  ): Promise<void> {
    const trimmedReportId = reportId.trim();
    const trimmedReason = reason?.trim();
    if (!trimmedReportId) {
      throw new Error('Report id is required.');
    }
    if (resolution !== 'under_review' && !trimmedReason) {
      throw new Error('A resolution reason is required.');
    }
    await this.gateway.resolveSessionReport(trimmedReportId, resolution, trimmedReason);
  }
}

@Injectable({ providedIn: 'root' })
export class ResolveSessionDisputeUseCase {
  constructor(
    @Inject(SESSION_MODERATION_GATEWAY)
    private readonly gateway: SessionModerationGateway,
  ) {}

  async execute(
    bookingId: string,
    disputeId: string,
    resolution: DisputeResolution,
    reason: string,
  ): Promise<void> {
    const trimmedBookingId = bookingId.trim();
    const trimmedDisputeId = disputeId.trim();
    const trimmedReason = reason.trim();
    if (!trimmedBookingId) {
      throw new Error('Booking id is required.');
    }
    if (!trimmedDisputeId) {
      throw new Error('Dispute id is required.');
    }
    if (!trimmedReason) {
      throw new Error('A dispute resolution reason is required.');
    }
    await this.gateway.resolveSessionDispute(
      trimmedBookingId,
      trimmedDisputeId,
      resolution,
      trimmedReason,
    );
  }
}
