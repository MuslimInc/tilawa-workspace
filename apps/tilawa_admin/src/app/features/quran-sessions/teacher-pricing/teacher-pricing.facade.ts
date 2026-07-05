import { Injectable, inject, signal } from '@angular/core';

import {
  SetTeacherPricingInput,
  TEACHER_PRICING_GATEWAY,
} from '../../../core/domain/repositories/teacher-pricing.gateway';

/** How the admin wants this teacher priced. */
export type TeacherPricingMode = 'inherit' | 'free' | 'fixed';

export interface TeacherPricingFormValue {
  readonly teacherId: string;
  readonly mode: TeacherPricingMode;
  readonly amount?: number | null;
  readonly currencyCode?: string | null;
}

/**
 * Pure translation of the admin form into a gateway write. Throws on invalid
 * input (fixed mode needs a finite amount >= 0). `inherit` clears the override
 * so the market price applies again; `free` writes amount 0.
 */
export function buildSetPricingInput(
  value: TeacherPricingFormValue,
): SetTeacherPricingInput {
  if (!value.teacherId) {
    throw new Error('teacherId is required.');
  }
  switch (value.mode) {
    case 'inherit':
      return { teacherId: value.teacherId, enabled: false };
    case 'free':
      return { teacherId: value.teacherId, enabled: true, amount: 0 };
    case 'fixed': {
      const amount = value.amount;
      if (typeof amount !== 'number' || !Number.isFinite(amount) || amount <= 0) {
        throw new Error('Enter a price greater than 0, or choose Free.');
      }
      const currencyCode =
        typeof value.currencyCode === 'string' && value.currencyCode.trim().length > 0
          ? value.currencyCode.trim().toUpperCase()
          : null;
      return { teacherId: value.teacherId, enabled: true, amount, currencyCode };
    }
  }
}

@Injectable({ providedIn: 'root' })
export class TeacherPricingFacade {
  private readonly gateway = inject(TEACHER_PRICING_GATEWAY);

  readonly isSubmitting = signal(false);
  readonly error = signal<string | null>(null);
  readonly saved = signal(false);

  async submit(value: TeacherPricingFormValue): Promise<boolean> {
    this.error.set(null);
    this.saved.set(false);
    this.isSubmitting.set(true);
    try {
      const input = buildSetPricingInput(value);
      await this.gateway.setTeacherPricing(input);
      this.saved.set(true);
      return true;
    } catch (e) {
      this.error.set(e instanceof Error ? e.message : 'Failed to update pricing.');
      return false;
    } finally {
      this.isSubmitting.set(false);
    }
  }

  reset(): void {
    this.error.set(null);
    this.saved.set(false);
  }
}
