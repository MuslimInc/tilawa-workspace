import { InjectionToken } from '@angular/core';

import {
  SessionDisputeFilters,
  SessionDisputeSummary,
} from '../entities/session-dispute-summary.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface SessionDisputeReadRepository {
  list(
    filters: SessionDisputeFilters,
    page: PageRequest,
  ): Promise<PageResult<SessionDisputeSummary>>;

  getById(disputeId: string): Promise<SessionDisputeSummary | null>;
}

export const SESSION_DISPUTE_READ_REPOSITORY = new InjectionToken<SessionDisputeReadRepository>(
  'SessionDisputeReadRepository',
);
