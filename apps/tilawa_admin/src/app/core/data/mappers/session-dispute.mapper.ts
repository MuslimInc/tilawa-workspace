import { SessionDisputeSummary } from '../../domain/entities/session-dispute-summary.entity';
import { readRequiredTimestamp, readTimestamp } from './quran-sessions.mapper';

export interface SessionDisputeFirestoreDto {
  disputeId?: string;
  aggregateId?: string;
  bookingId?: string;
  sessionId?: string | null;
  status?: string;
  reason?: string;
  openedByUserId?: string;
  openedByRole?: string;
  resolutionReason?: string;
  resolvedByUserId?: string;
  createdAt?: unknown;
  updatedAt?: unknown;
  resolvedAt?: unknown;
}

export abstract class SessionDisputeMapper {
  static fromFirestore(id: string, data: SessionDisputeFirestoreDto): SessionDisputeSummary {
    return {
      id,
      bookingId: data.bookingId ?? '',
      sessionId: data.sessionId ?? null,
      aggregateId: data.aggregateId ?? data.bookingId ?? id,
      status: (data.status as SessionDisputeSummary['status']) ?? 'opened',
      reason: data.reason ?? '',
      openedByUserId: data.openedByUserId ?? '',
      openedByRole: data.openedByRole ?? 'user',
      resolutionReason: data.resolutionReason ?? null,
      resolvedByUserId: data.resolvedByUserId ?? null,
      createdAt: readRequiredTimestamp(data.createdAt, new Date(0)),
      updatedAt: readTimestamp(data.updatedAt),
      resolvedAt: readTimestamp(data.resolvedAt),
    };
  }
}
