export type SessionReportStatus =
  | 'open'
  | 'under_review'
  | 'resolved'
  | 'dismissed';

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
  createdAt: Date;
  updatedAt: Date | null;
}

export interface SessionReportFilters {
  status: SessionReportStatus | null;
  severity: SessionReportSeverity | null;
  category: string | null;
  search: string | null;
}
