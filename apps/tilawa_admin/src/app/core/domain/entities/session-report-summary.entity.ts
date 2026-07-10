export type SessionReportStatus = 'open' | 'under_review' | 'resolved' | 'dismissed';

export type SessionReportResolution = Exclude<SessionReportStatus, 'open'>;

export type SessionReportSeverity = 'high' | 'normal';

export interface SessionReportSummary {
  id: string;
  bookingId: string | null;
  sessionId: string | null;
  category: string;
  description: string;
  severity: SessionReportSeverity;
  status: SessionReportStatus;
  reporterUserId: string;
  reporterRole: string;
  reportedUserId: string | null;
  resolutionReason: string | null;
  resolvedByUserId: string | null;
  createdAt: Date;
  updatedAt: Date | null;
  resolvedAt: Date | null;
}

export interface SessionReportFilters {
  status: SessionReportStatus | null;
  severity: SessionReportSeverity | null;
  category: string | null;
  search: string | null;
}

export const SESSION_REPORT_DEFAULT_SORT = {
  field: 'createdAt',
  direction: 'desc',
} as const;

export const SESSION_REPORT_SORT_FIELDS = ['createdAt', 'updatedAt'] as const;
