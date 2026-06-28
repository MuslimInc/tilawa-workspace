import { SessionLifecycleStatus } from './session-lifecycle-status.enum';

export interface AdminSessionSummary {
  readonly id: string;
  readonly aggregateId: string;
  readonly sessionId: string | null;
  readonly studentId: string;
  readonly teacherId: string;
  readonly slotId: string;
  readonly startsAt: Date;
  readonly endsAt: Date | null;
  readonly lifecycleStatus: SessionLifecycleStatus;
  readonly callType: string;
  readonly pricingType: string;
  readonly countryCode: string | null;
  readonly cityId: string | null;
  readonly paymentStatus: string | null;
  readonly amountPaidUsd: number | null;
  readonly cancellationReason: string | null;
  readonly hasActiveCall: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface AdminSessionFilters {
  readonly status: SessionLifecycleStatus | null;
  readonly teacherId: string | null;
  readonly studentId: string | null;
  readonly startsFrom: Date | null;
  readonly startsTo: Date | null;
  readonly countryCode: string | null;
  readonly cityId: string | null;
  readonly search: string | null;
}

export const ADMIN_SESSION_DEFAULT_SORT = {
  field: 'startsAt',
  direction: 'desc',
} as const;

export const ADMIN_SESSION_SORT_FIELDS = ['startsAt', 'createdAt', 'updatedAt'] as const;
