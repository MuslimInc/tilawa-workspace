import { Inject, Injectable } from '@angular/core';

import { SessionCompensationSummary } from '../entities/session-compensation-summary.entity';
import { SessionTimelineEvent } from '../entities/session-timeline-event.entity';
import {
  SESSION_AUDIT_REPOSITORY,
  SessionAuditRepository,
} from '../repositories/session-audit.repository';

@Injectable({ providedIn: 'root' })
export class GetSessionTimelineUseCase {
  constructor(
    @Inject(SESSION_AUDIT_REPOSITORY)
    private readonly repository: SessionAuditRepository,
  ) {}

  execute(aggregateId: string): Promise<readonly SessionTimelineEvent[]> {
    return this.repository.listTimelineByAggregateId(aggregateId);
  }
}

@Injectable({ providedIn: 'root' })
export class ListSessionCompensationsUseCase {
  constructor(
    @Inject(SESSION_AUDIT_REPOSITORY)
    private readonly repository: SessionAuditRepository,
  ) {}

  execute(bookingId: string): Promise<readonly SessionCompensationSummary[]> {
    return this.repository.listCompensationsByBookingId(bookingId);
  }
}
