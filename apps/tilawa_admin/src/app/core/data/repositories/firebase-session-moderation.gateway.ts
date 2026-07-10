import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';

import {
  DisputeResolution,
  NoShowClassification,
  SessionCompensationType,
} from '../../domain/entities/session-moderation.types';
import { SessionReportResolution } from '../../domain/entities/session-report-summary.entity';
import { SessionModerationGateway } from '../../domain/repositories/session-moderation.gateway';
import { mapCallableFunctionError } from './callable-function-error.util';

@Injectable({ providedIn: 'root' })
export class FirebaseSessionModerationGateway implements SessionModerationGateway {
  private readonly functions = inject(Functions);

  async cancelSessionBooking(bookingId: string, reason: string): Promise<void> {
    await this.invokeCallable('cancelSessionBooking', {
      bookingId,
      reason,
      actorRole: 'admin',
    });
  }

  async markSessionNoShow(sessionId: string, classification: NoShowClassification): Promise<void> {
    await this.invokeCallable('markSessionNoShow', {
      sessionId,
      classification,
    });
  }

  async completeSession(sessionId: string): Promise<void> {
    await this.invokeCallable('completeSession', { sessionId });
  }

  async issueSessionCompensation(
    bookingId: string,
    compensationType: SessionCompensationType,
    reason: string,
    amountUsd?: number,
  ): Promise<void> {
    await this.invokeCallable('issueSessionCompensation', {
      bookingId,
      compensationType,
      reason,
      amountUsd,
    });
  }

  async confirmSessionReschedule(requestId: string, accept: boolean): Promise<void> {
    await this.invokeCallable('confirmSessionReschedule', {
      requestId,
      accept,
      actorRole: 'admin',
    });
  }

  async approveSessionRefund(bookingId: string, reason: string): Promise<void> {
    await this.invokeCallable('approveSessionRefund', {
      bookingId,
      reason,
    });
  }

  async confirmManualBookingPayment(bookingId: string, note?: string): Promise<void> {
    await this.invokeCallable('confirmManualBookingPayment', {
      bookingId,
      ...(note ? { note } : {}),
    });
  }

  async rejectManualBookingPayment(bookingId: string, reason?: string): Promise<void> {
    await this.invokeCallable('rejectManualBookingPayment', {
      bookingId,
      ...(reason ? { reason } : {}),
    });
  }

  async openSessionDispute(
    bookingId: string,
    reason: string,
    evidenceMetadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.invokeCallable('openSessionDispute', {
      bookingId,
      reason,
      evidenceMetadata,
    });
  }

  async resolveSessionReport(
    reportId: string,
    resolution: SessionReportResolution,
    reason?: string,
  ): Promise<void> {
    await this.invokeCallable('resolveSessionReport', {
      reportId,
      resolution,
      ...(reason ? { reason } : {}),
    });
  }

  async resolveSessionDispute(
    bookingId: string,
    disputeId: string,
    resolution: DisputeResolution,
    reason: string,
  ): Promise<void> {
    await this.invokeCallable('resolveSessionDispute', {
      bookingId,
      disputeId,
      resolution,
      reason,
    });
  }

  private async invokeCallable(name: string, data: Record<string, unknown>): Promise<void> {
    const callable = httpsCallable(this.functions, name);

    try {
      await callable(data);
    } catch (error) {
      throw new Error(mapCallableFunctionError(error, name));
    }
  }
}
