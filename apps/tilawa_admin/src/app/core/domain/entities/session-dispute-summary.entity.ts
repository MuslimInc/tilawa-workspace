export type SessionDisputeStatus =
  | 'none'
  | 'opened'
  | 'under_review'
  | 'resolved_favor_student'
  | 'resolved_favor_teacher'
  | 'resolved_with_compensation'
  | 'rejected'
  | 'closed';

export interface SessionDisputeSummary {
  id: string;
  bookingId: string;
  sessionId: string | null;
  aggregateId: string;
  status: SessionDisputeStatus;
  reason: string;
  openedByUserId: string;
  openedByRole: string;
  resolutionReason: string | null;
  resolvedByUserId: string | null;
  createdAt: Date;
  updatedAt: Date | null;
  resolvedAt: Date | null;
}

export interface SessionDisputeFilters {
  status: SessionDisputeStatus | null;
  search: string | null;
}
