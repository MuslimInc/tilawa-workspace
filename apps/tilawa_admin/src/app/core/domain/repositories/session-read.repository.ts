import { InjectionToken } from '@angular/core';

import {
  AdminSessionFilters,
  AdminSessionSummary,
} from '../entities/admin-session-summary.entity';
import {
  ActiveSessionFilters,
} from '../entities/active-session.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface SessionReadRepository {
  list(
    filters: AdminSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>>;

  /**
   * Bounded operational window query — server-side `startsAt` range +
   * `lifecycleStatus in (...)` only. Never scans the full collection.
   */
  listActive(
    filters: ActiveSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>>;

  getById(bookingId: string): Promise<AdminSessionSummary | null>;
}

export const SESSION_READ_REPOSITORY = new InjectionToken<SessionReadRepository>(
  'SessionReadRepository',
);
