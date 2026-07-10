import { describe, expect, it, vi, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { SessionsFacade } from './sessions.facade';
import { SessionReportsFacade } from './session-reports.facade';
import {
  ListAdminSessionsUseCase,
  GetAdminSessionUseCase,
} from '../../domain/usecases/session.usecases';
import {
  GetSessionTimelineUseCase,
  ListSessionCompensationsUseCase,
} from '../../domain/usecases/session-audit.usecases';
import {
  GetCallTrackingSummaryUseCase,
  ListCallEventsUseCase,
} from '../../domain/usecases/call-tracking.usecases';
import {
  CancelSessionUseCase,
  MarkSessionNoShowUseCase,
  CompleteSessionUseCase,
  IssueSessionCompensationUseCase,
  ConfirmSessionRescheduleUseCase,
  ApproveSessionRefundUseCase,
  ConfirmManualBookingPaymentUseCase,
  RejectManualBookingPaymentUseCase,
} from '../../domain/usecases/session-moderation.usecases';
import { ListSessionReportsUseCase } from '../../domain/usecases/session-report.usecases';
import { GetSessionReportUseCase } from '../../domain/usecases/session-report.usecases';
import { TEACHER_PROFILE_REPOSITORY } from '../../domain/repositories/teacher-profile.repository';
import { QURAN_SESSIONS_USER_REPOSITORY } from '../../domain/repositories/quran-sessions-user.repository';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';

const noopUseCase = { execute: vi.fn() };

const sessionFilters = {
  search: null,
  status: null,
  teacherId: null,
  studentId: null,
  countryCode: null,
  cityId: null,
  startsFrom: null,
  startsTo: null,
};

describe('browse list facades — filter change resets cursor', () => {
  describe('SessionsFacade', () => {
    let facade: SessionsFacade;
    const listUseCase = { execute: vi.fn() };

    beforeEach(() => {
      listUseCase.execute.mockReset();
      listUseCase.execute.mockResolvedValue({
        items: [{ id: 'b1' }],
        nextCursor: 'b1',
        hasMore: true,
      });
      TestBed.configureTestingModule({
        providers: [
          SessionsFacade,
          { provide: ListAdminSessionsUseCase, useValue: listUseCase },
          { provide: GetAdminSessionUseCase, useValue: noopUseCase },
          { provide: GetSessionTimelineUseCase, useValue: noopUseCase },
          { provide: ListSessionCompensationsUseCase, useValue: noopUseCase },
          { provide: GetCallTrackingSummaryUseCase, useValue: noopUseCase },
          { provide: ListCallEventsUseCase, useValue: noopUseCase },
          { provide: CancelSessionUseCase, useValue: noopUseCase },
          { provide: MarkSessionNoShowUseCase, useValue: noopUseCase },
          { provide: CompleteSessionUseCase, useValue: noopUseCase },
          { provide: IssueSessionCompensationUseCase, useValue: noopUseCase },
          { provide: ConfirmSessionRescheduleUseCase, useValue: noopUseCase },
          { provide: ApproveSessionRefundUseCase, useValue: noopUseCase },
          { provide: ConfirmManualBookingPaymentUseCase, useValue: noopUseCase },
          { provide: RejectManualBookingPaymentUseCase, useValue: noopUseCase },
          {
            provide: TEACHER_PROFILE_REPOSITORY,
            useValue: { list: vi.fn(), getById: vi.fn() },
          },
          {
            provide: QURAN_SESSIONS_USER_REPOSITORY,
            useValue: {
              list: vi.fn(),
              listMatchingUserIds: vi.fn(),
              getById: vi.fn(),
              getByIds: vi.fn(),
            },
          },
        ],
      });
      facade = TestBed.inject(SessionsFacade);
    });

    it('reload after a filter change starts at page 1 (cursor null), not append', async () => {
      await facade.loadList(sessionFilters);
      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        sessionFilters,
        expect.objectContaining({ cursor: null }),
      );

      const filtered = {
        ...sessionFilters,
        status: SessionLifecycleStatus.Scheduled,
      };
      await facade.loadList(filtered);

      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        filtered,
        expect.objectContaining({ cursor: null }),
      );
      // filter reload replaces the list (no append of the prior page)
      expect(listUseCase.execute).toHaveBeenCalledTimes(2);
    });
  });

  describe('SessionReportsFacade', () => {
    let facade: SessionReportsFacade;
    const listUseCase = { execute: vi.fn() };

    beforeEach(() => {
      listUseCase.execute.mockReset();
      listUseCase.execute.mockResolvedValue({
        items: [{ id: 'r1' }],
        nextCursor: 'r1',
        hasMore: true,
      });
      TestBed.configureTestingModule({
        providers: [
          SessionReportsFacade,
          { provide: ListSessionReportsUseCase, useValue: listUseCase },
          { provide: GetSessionReportUseCase, useValue: noopUseCase },
        ],
      });
      facade = TestBed.inject(SessionReportsFacade);
    });

    it('changing the status filter reloads from page 1 with cursor null', async () => {
      await facade.loadList({ status: null, severity: null, category: null, search: null });
      await facade.loadList({ status: 'open', severity: null, category: null, search: null });

      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        { status: 'open', severity: null, category: null, search: null },
        expect.objectContaining({ cursor: null }),
      );
    });
  });
});
