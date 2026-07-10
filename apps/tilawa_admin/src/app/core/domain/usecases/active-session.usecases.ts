import { Inject, Injectable } from '@angular/core';

import { ActiveSessionFilters } from '../entities/active-session.entity';
import { AdminSessionSummary } from '../entities/admin-session-summary.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  SESSION_READ_REPOSITORY,
  SessionReadRepository,
} from '../repositories/session-read.repository';

@Injectable({ providedIn: 'root' })
export class ListActiveAdminSessionsUseCase {
  constructor(
    @Inject(SESSION_READ_REPOSITORY)
    private readonly repository: SessionReadRepository,
  ) {}

  execute(
    filters: ActiveSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>> {
    return this.repository.listActive(filters, page);
  }
}
