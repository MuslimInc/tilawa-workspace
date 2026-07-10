import { InjectionToken } from '@angular/core';

import {
  SessionReportFilters,
  SessionReportSummary,
} from '../entities/session-report-summary.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface SessionReportReadRepository {
  list(filters: SessionReportFilters, page: PageRequest): Promise<PageResult<SessionReportSummary>>;

  getById(reportId: string): Promise<SessionReportSummary | null>;
}

export const SESSION_REPORT_READ_REPOSITORY = new InjectionToken<SessionReportReadRepository>(
  'SESSION_REPORT_READ_REPOSITORY',
);
