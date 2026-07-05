import { Inject, Injectable } from '@angular/core';

import { CallEvent, CallTrackingSummary } from '../entities/call-tracking.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  CALL_TRACKING_REPOSITORY,
  CallTrackingRepository,
} from '../repositories/call-tracking.repository';

@Injectable({ providedIn: 'root' })
export class GetCallTrackingSummaryUseCase {
  constructor(
    @Inject(CALL_TRACKING_REPOSITORY)
    private readonly repository: CallTrackingRepository,
  ) {}

  execute(sessionId: string): Promise<CallTrackingSummary | null> {
    return this.repository.getSummary(sessionId);
  }
}

@Injectable({ providedIn: 'root' })
export class ListCallEventsUseCase {
  constructor(
    @Inject(CALL_TRACKING_REPOSITORY)
    private readonly repository: CallTrackingRepository,
  ) {}

  execute(sessionId: string, page: PageRequest): Promise<PageResult<CallEvent>> {
    return this.repository.listEvents(sessionId, page);
  }
}
