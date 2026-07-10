import { InjectionToken } from '@angular/core';

/** Admin write to set/clear a teacher's session price override. */
export interface SetTeacherPricingInput {
  readonly teacherId: string;
  /** false ⇒ clear the override (inherit market price). */
  readonly enabled: boolean;
  /** Required when enabled; 0 = free. Ignored when disabled. */
  readonly amount?: number;
  /** Optional ISO 4217; falls back to the market currency server-side. */
  readonly currencyCode?: string | null;
}

/** Privileged teacher pricing writes — callable Cloud Functions only. */
export interface TeacherPricingGateway {
  setTeacherPricing(input: SetTeacherPricingInput): Promise<void>;
}

export const TEACHER_PRICING_GATEWAY = new InjectionToken<TeacherPricingGateway>(
  'TeacherPricingGateway',
);
