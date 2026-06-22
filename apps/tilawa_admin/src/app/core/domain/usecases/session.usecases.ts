import { Inject, Injectable } from '@angular/core';

import {
  AdminSessionFilters,
  AdminSessionSummary,
} from '../entities/admin-session-summary.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  SESSION_READ_REPOSITORY,
  SessionReadRepository,
} from '../repositories/session-read.repository';

@Injectable({ providedIn: 'root' })
export class ListAdminSessionsUseCase {
  constructor(
    @Inject(SESSION_READ_REPOSITORY)
    private readonly repository: SessionReadRepository,
  ) {}

  execute(
    filters: AdminSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>> {
    return this.repository.list(filters, page);
  }
}

@Injectable({ providedIn: 'root' })
export class GetAdminSessionUseCase {
  constructor(
    @Inject(SESSION_READ_REPOSITORY)
    private readonly repository: SessionReadRepository,
  ) {}

  execute(bookingId: string): Promise<AdminSessionSummary | null> {
    return this.repository.getById(bookingId);
  }
}
