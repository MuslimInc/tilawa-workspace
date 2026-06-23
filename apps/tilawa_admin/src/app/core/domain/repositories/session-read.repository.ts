import { InjectionToken } from '@angular/core';

import {
  AdminSessionFilters,
  AdminSessionSummary,
} from '../entities/admin-session-summary.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface SessionReadRepository {
  list(
    filters: AdminSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>>;

  getById(bookingId: string): Promise<AdminSessionSummary | null>;
}

export const SESSION_READ_REPOSITORY = new InjectionToken<SessionReadRepository>(
  'SessionReadRepository',
);
