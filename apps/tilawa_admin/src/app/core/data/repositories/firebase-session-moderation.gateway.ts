import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';

import {
  DisputeResolution,
  NoShowClassification,
  SessionCompensationType,
} from '../../domain/entities/session-moderation.types';
import { SessionModerationGateway } from '../../domain/repositories/session-moderation.gateway';

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

  async markSessionNoShow(
    sessionId: string,
    classification: NoShowClassification,
  ): Promise<void> {
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

  async confirmSessionReschedule(
    requestId: string,
    accept: boolean,
  ): Promise<void> {
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

  private async invokeCallable(
    name: string,
    data: Record<string, unknown>,
  ): Promise<void> {
    const callable = httpsCallable(this.functions, name);

    try {
      await callable(data);
    } catch (error) {
      throw new Error(this.toErrorMessage(error, name));
    }
  }

  private toErrorMessage(error: unknown, functionName: string): string {
    if (isCallableError(error)) {
      if (error.code === 'functions/not-found') {
        return `${functionName} is not deployed. Run firebase deploy --only functions.`;
      }

      return error.message || `${functionName} failed (${error.code}).`;
    }

    if (error instanceof Error) {
      if (error.message === 'internal') {
        return `${functionName} failed. Deploy Cloud Functions and retry.`;
      }

      return error.message;
    }

    return `${functionName} failed.`;
  }
}

function isCallableError(
  error: unknown,
): error is { code: string; message: string } {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof (error as { code: unknown }).code === 'string' &&
    'message' in error &&
    typeof (error as { message: unknown }).message === 'string'
  );
}
