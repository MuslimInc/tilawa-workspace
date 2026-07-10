import { SessionReportSummary } from '../../domain/entities/session-report-summary.entity';
import { readRequiredTimestamp, readTimestamp } from './quran-sessions.mapper';

export interface SessionReportFirestoreDto {
  reportId?: string;
  bookingId?: string | null;
  sessionId?: string | null;
  category?: string;
  description?: string;
  severity?: string;
  status?: string;
  reporterUserId?: string;
  reporterRole?: string;
  reportedUserId?: string | null;
  createdAt?: unknown;
  updatedAt?: unknown;
}

export abstract class SessionReportMapper {
  static fromFirestore(id: string, data: SessionReportFirestoreDto): SessionReportSummary {
    return {
      id,
      bookingId: data.bookingId ?? null,
      sessionId: data.sessionId ?? null,
      category: data.category ?? 'other',
      description: data.description ?? '',
      severity: data.severity === 'high' ? 'high' : 'normal',
      status: (data.status as SessionReportSummary['status']) ?? 'open',
      reporterUserId: data.reporterUserId ?? '',
      reporterRole: data.reporterRole ?? 'user',
      reportedUserId: data.reportedUserId ?? null,
      createdAt: readRequiredTimestamp(data.createdAt, new Date(0)),
      updatedAt: readTimestamp(data.updatedAt),
    };
  }
}
