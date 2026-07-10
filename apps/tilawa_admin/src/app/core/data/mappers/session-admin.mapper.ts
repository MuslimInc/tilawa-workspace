import { AdminSessionSummary } from '../../domain/entities/admin-session-summary.entity';
import { SessionCompensationSummary } from '../../domain/entities/session-compensation-summary.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import { SessionTimelineEvent } from '../../domain/entities/session-timeline-event.entity';
import { readRequiredTimestamp, readTimestamp } from './quran-sessions.mapper';

export interface BookingFirestoreDto {
  bookingId?: string;
  aggregateId?: string;
  sessionId?: string;
  studentId?: string;
  teacherId?: string;
  slotId?: string;
  startsAt?: unknown;
  endsAt?: unknown;
  callType?: string;
  pricingType?: string;
  lifecycleStatus?: string;
  status?: string;
  countryCode?: string;
  cityId?: string;
  paymentStatus?: string;
  paymentReference?: string | null;
  paymentProvider?: string | null;
  priceAmount?: number | null;
  priceCurrency?: string | null;
  amountPaidUsd?: number;
  cancellationReason?: string;
  hasActiveCall?: boolean;
  createdAt?: unknown;
  updatedAt?: unknown;
}

export interface SessionEventFirestoreDto {
  aggregateId?: string;
  bookingId?: string;
  sessionId?: string;
  actorId?: string;
  actorRole?: string;
  action?: string;
  previousStatus?: string;
  newStatus?: string;
  reason?: string;
  source?: string;
  timestamp?: unknown;
}

export interface CompensationFirestoreDto {
  compensationId?: string;
  aggregateId?: string;
  bookingId?: string;
  type?: string;
  status?: string;
  policyRuleId?: string;
  amountUsd?: number;
  issuedByActorId?: string;
  issuedByRole?: string;
  failureReason?: string;
  createdAt?: unknown;
  completedAt?: unknown;
}

export function parseSessionLifecycleStatus(raw: string | undefined): SessionLifecycleStatus {
  if (!raw) {
    return SessionLifecycleStatus.Unknown;
  }
  const values = Object.values(SessionLifecycleStatus);
  return values.includes(raw as SessionLifecycleStatus)
    ? (raw as SessionLifecycleStatus)
    : SessionLifecycleStatus.Unknown;
}

export function resolveLifecycleStatus(dto: BookingFirestoreDto): SessionLifecycleStatus {
  return parseSessionLifecycleStatus(dto.lifecycleStatus ?? dto.status);
}

export class AdminSessionMapper {
  static fromBookingDoc(id: string, dto: BookingFirestoreDto): AdminSessionSummary {
    const now = new Date();
    return {
      id,
      aggregateId: dto.aggregateId ?? id,
      sessionId: dto.sessionId ?? null,
      studentId: dto.studentId ?? '',
      teacherId: dto.teacherId ?? '',
      slotId: dto.slotId ?? '',
      startsAt: readRequiredTimestamp(dto.startsAt, now),
      endsAt: readTimestamp(dto.endsAt),
      lifecycleStatus: resolveLifecycleStatus(dto),
      callType: dto.callType ?? 'externalMeeting',
      pricingType: dto.pricingType ?? 'free',
      countryCode: dto.countryCode ?? null,
      cityId: dto.cityId ?? null,
      paymentStatus: dto.paymentStatus ?? null,
      paymentReference: dto.paymentReference ?? null,
      paymentProvider: dto.paymentProvider ?? null,
      priceAmount: dto.priceAmount ?? null,
      priceCurrency: dto.priceCurrency ?? null,
      amountPaidUsd: dto.amountPaidUsd ?? null,
      cancellationReason: dto.cancellationReason ?? null,
      hasActiveCall: dto.hasActiveCall === true,
      createdAt: readRequiredTimestamp(dto.createdAt, now),
      updatedAt: readRequiredTimestamp(dto.updatedAt, now),
    };
  }
}

export class SessionTimelineMapper {
  static fromFirestore(id: string, dto: SessionEventFirestoreDto): SessionTimelineEvent {
    const now = new Date();
    return {
      id,
      aggregateId: dto.aggregateId ?? '',
      bookingId: dto.bookingId ?? null,
      sessionId: dto.sessionId ?? null,
      actorId: dto.actorId ?? 'system',
      actorRole: dto.actorRole ?? 'system',
      action: dto.action ?? 'unknown',
      previousStatus: dto.previousStatus ?? null,
      newStatus: dto.newStatus ?? 'unknown',
      reason: dto.reason ?? null,
      source: dto.source ?? 'backendJob',
      timestamp: readRequiredTimestamp(dto.timestamp, now),
    };
  }
}

export class SessionCompensationMapper {
  static fromFirestore(id: string, dto: CompensationFirestoreDto): SessionCompensationSummary {
    const now = new Date();
    return {
      id: dto.compensationId ?? id,
      aggregateId: dto.aggregateId ?? '',
      bookingId: dto.bookingId ?? '',
      type: dto.type ?? 'unknown',
      status: dto.status ?? 'pending',
      policyRuleId: dto.policyRuleId ?? 'unknown',
      amountUsd: dto.amountUsd ?? null,
      issuedByActorId: dto.issuedByActorId ?? '',
      issuedByRole: dto.issuedByRole ?? 'admin',
      failureReason: dto.failureReason ?? null,
      createdAt: readRequiredTimestamp(dto.createdAt, now),
      completedAt: readTimestamp(dto.completedAt),
    };
  }
}
