import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';

import {
  SetTeacherPricingInput,
  TeacherPricingGateway,
} from '../../domain/repositories/teacher-pricing.gateway';

@Injectable({ providedIn: 'root' })
export class FirebaseTeacherPricingGateway implements TeacherPricingGateway {
  private readonly functions = inject(Functions);

  async setTeacherPricing(input: SetTeacherPricingInput): Promise<void> {
    const callable = httpsCallable(this.functions, 'setTeacherSessionPricing');
    try {
      await callable({
        teacherId: input.teacherId,
        enabled: input.enabled,
        // Only send pricing fields when enabling; the server ignores them
        // otherwise, but omitting keeps the payload honest.
        ...(input.enabled
          ? { amount: input.amount, currencyCode: input.currencyCode ?? undefined }
          : {}),
      });
    } catch (error) {
      throw new Error(this.toErrorMessage(error));
    }
  }

  private toErrorMessage(error: unknown): string {
    if (isCallableError(error)) {
      if (error.code === 'functions/not-found') {
        return 'setTeacherSessionPricing is not deployed. Run firebase deploy --only functions.';
      }
      return error.message || `Failed to update pricing (${error.code}).`;
    }
    if (error instanceof Error) {
      return error.message;
    }
    return 'Failed to update teacher pricing.';
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
