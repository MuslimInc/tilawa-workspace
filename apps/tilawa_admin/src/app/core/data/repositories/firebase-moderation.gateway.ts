import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';

import {
  ApplicationModerationAction,
  TeacherProfileModerationAction,
  UserModerationAction,
} from '../../domain/entities/moderation-action.enum';
import { ModerationGateway } from '../../domain/repositories/moderation.gateway';

@Injectable({ providedIn: 'root' })
export class FirebaseModerationGateway implements ModerationGateway {
  private readonly functions = inject(Functions);

  async reviewTeacherApplication(
    applicationId: string,
    action: ApplicationModerationAction,
    reason?: string,
  ): Promise<void> {
    await this.invokeCallable('reviewTeacherApplication', {
      applicationId,
      action,
      reason,
    });
  }

  async moderateTeacherProfile(
    teacherId: string,
    action: TeacherProfileModerationAction,
    reason?: string,
  ): Promise<void> {
    await this.invokeCallable('moderateTeacherProfile', {
      teacherId,
      action,
      reason,
    });
  }

  async moderateQuranSessionsUser(
    userId: string,
    action: UserModerationAction,
    reason?: string,
  ): Promise<void> {
    await this.invokeCallable('moderateQuranSessionsUser', {
      userId,
      action,
      reason,
    });
  }

  async setUserTeacherApplicationAccess(
    userId: string,
    canApplyAsTeacher: boolean | null,
  ): Promise<void> {
    await this.invokeCallable('setTeacherApplicationAccess', {
      userId,
      canApplyAsTeacher,
    });
  }

  private async invokeCallable(name: string, data: Record<string, unknown>): Promise<void> {
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

function isCallableError(error: unknown): error is { code: string; message: string } {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof (error as { code: unknown }).code === 'string' &&
    'message' in error &&
    typeof (error as { message: unknown }).message === 'string'
  );
}
