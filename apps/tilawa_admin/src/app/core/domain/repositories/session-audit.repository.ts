import { InjectionToken } from '@angular/core';

import { SessionCompensationSummary } from '../entities/session-compensation-summary.entity';
import { SessionTimelineEvent } from '../entities/session-timeline-event.entity';

export interface SessionAuditRepository {
  listTimelineByAggregateId(
    aggregateId: string,
  ): Promise<readonly SessionTimelineEvent[]>;

  listCompensationsByBookingId(
    bookingId: string,
  ): Promise<readonly SessionCompensationSummary[]>;
}

export const SESSION_AUDIT_REPOSITORY = new InjectionToken<SessionAuditRepository>(
  'SessionAuditRepository',
);
