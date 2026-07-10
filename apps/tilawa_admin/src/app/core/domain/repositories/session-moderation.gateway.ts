import { InjectionToken } from '@angular/core';

import {
  NoShowClassification,
  SessionCompensationType,
} from '../entities/session-moderation.types';

/** Privileged session lifecycle writes — callable Cloud Functions only. */
export interface SessionModerationGateway {
  cancelSessionBooking(bookingId: string, reason: string): Promise<void>;

  markSessionNoShow(sessionId: string, classification: NoShowClassification): Promise<void>;

  completeSession(sessionId: string): Promise<void>;

  issueSessionCompensation(
    bookingId: string,
    compensationType: SessionCompensationType,
    reason: string,
    amountUsd?: number,
  ): Promise<void>;

  confirmSessionReschedule(requestId: string, accept: boolean): Promise<void>;

  approveSessionRefund(bookingId: string, reason: string): Promise<void>;

  confirmManualBookingPayment(bookingId: string, note?: string): Promise<void>;

  rejectManualBookingPayment(bookingId: string, reason?: string): Promise<void>;

  openSessionDispute(
    bookingId: string,
    reason: string,
    evidenceMetadata?: Record<string, unknown>,
  ): Promise<void>;

  resolveSessionDispute(
    bookingId: string,
    disputeId: string,
    resolution: import('../entities/session-moderation.types').DisputeResolution,
    reason: string,
  ): Promise<void>;
}

export const SESSION_MODERATION_GATEWAY = new InjectionToken<SessionModerationGateway>(
  'SessionModerationGateway',
);
