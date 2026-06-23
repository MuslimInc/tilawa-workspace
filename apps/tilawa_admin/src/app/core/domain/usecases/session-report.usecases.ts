import { Inject, Injectable } from '@angular/core';

import {
  SessionReportFilters,
  SessionReportSummary,
} from '../entities/session-report-summary.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  SESSION_REPORT_READ_REPOSITORY,
  SessionReportReadRepository,
} from '../repositories/session-report-read.repository';

@Injectable({ providedIn: 'root' })
export class ListSessionReportsUseCase {
  constructor(
    @Inject(SESSION_REPORT_READ_REPOSITORY)
    private readonly repository: SessionReportReadRepository,
  ) {}

  execute(
    filters: SessionReportFilters,
    page: PageRequest,
  ): Promise<PageResult<SessionReportSummary>> {
    return this.repository.list(filters, page);
  }
}

@Injectable({ providedIn: 'root' })
export class GetSessionReportUseCase {
  constructor(
    @Inject(SESSION_REPORT_READ_REPOSITORY)
    private readonly repository: SessionReportReadRepository,
  ) {}

  execute(reportId: string): Promise<SessionReportSummary | null> {
    return this.repository.getById(reportId);
  }
}
