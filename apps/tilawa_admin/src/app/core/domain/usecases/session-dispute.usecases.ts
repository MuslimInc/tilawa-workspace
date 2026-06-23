import { Inject, Injectable } from '@angular/core';

import {
  SessionDisputeFilters,
  SessionDisputeSummary,
} from '../entities/session-dispute-summary.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  SESSION_DISPUTE_READ_REPOSITORY,
  SessionDisputeReadRepository,
} from '../repositories/session-dispute-read.repository';

@Injectable({ providedIn: 'root' })
export class ListSessionDisputesUseCase {
  constructor(
    @Inject(SESSION_DISPUTE_READ_REPOSITORY)
    private readonly repository: SessionDisputeReadRepository,
  ) {}

  execute(
    filters: SessionDisputeFilters,
    page: PageRequest,
  ): Promise<PageResult<SessionDisputeSummary>> {
    return this.repository.list(filters, page);
  }
}

@Injectable({ providedIn: 'root' })
export class GetSessionDisputeUseCase {
  constructor(
    @Inject(SESSION_DISPUTE_READ_REPOSITORY)
    private readonly repository: SessionDisputeReadRepository,
  ) {}

  execute(disputeId: string): Promise<SessionDisputeSummary | null> {
    return this.repository.getById(disputeId);
  }
}
