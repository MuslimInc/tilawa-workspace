import { describe, expect, it, vi, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { TeacherApplicationsFacade } from './teacher-applications.facade';
import { TeachersFacade } from './teachers.facade';
import { SessionsFacade } from './sessions.facade';
import { SessionReportsFacade } from './session-reports.facade';
import { SessionDisputesFacade } from './session-disputes.facade';
import { ListTeacherApplicationsUseCase } from '../../domain/usecases/teacher-application.usecases';
import { GetTeacherApplicationUseCase } from '../../domain/usecases/teacher-application.usecases';
import { ReviewTeacherApplicationUseCase } from '../../domain/usecases/review-teacher-application.usecase';
import {
  ListTeachersUseCase,
  ModerateTeacherProfileUseCase,
} from '../../domain/usecases/teacher-profile.usecases';
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
import { TEACHER_PROFILE_REPOSITORY } from '../../domain/repositories/teacher-profile.repository';
import { QURAN_SESSIONS_USER_REPOSITORY } from '../../domain/repositories/quran-sessions-user.repository';
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
import { ListSessionDisputesUseCase } from '../../domain/usecases/session-dispute.usecases';
import { GetSessionDisputeUseCase } from '../../domain/usecases/session-dispute.usecases';
import { SESSION_READ_REPOSITORY } from '../../domain/repositories/session-read.repository';

const emptyPage = { items: [], nextCursor: null, hasMore: false };
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

const reportFilters = {
  status: null,
  severity: null,
  category: null,
  search: null,
};

describe('browse list facades sort', () => {
  describe('TeacherApplicationsFacade', () => {
    const listUseCase = { execute: vi.fn() };

    beforeEach(() => {
      listUseCase.execute.mockReset();
      listUseCase.execute.mockResolvedValue(emptyPage);
      TestBed.configureTestingModule({
        providers: [
          TeacherApplicationsFacade,
          { provide: ListTeacherApplicationsUseCase, useValue: listUseCase },
          { provide: GetTeacherApplicationUseCase, useValue: noopUseCase },
          { provide: ReviewTeacherApplicationUseCase, useValue: noopUseCase },
          {
            provide: QURAN_SESSIONS_USER_REPOSITORY,
            useValue: { getByIds: vi.fn().mockResolvedValue(new Map()) },
          },
        ],
      });
    });

    it('resets cursor on changeSort', async () => {
      const facade = TestBed.inject(TeacherApplicationsFacade);
      await facade.loadList({});
      await facade.changeSort({}, { field: 'submittedAt', direction: 'asc' });

      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        {},
        expect.objectContaining({
          cursor: null,
          sort: { field: 'submittedAt', direction: 'asc' },
        }),
      );
      expect(facade.sort()).toEqual({ field: 'submittedAt', direction: 'asc' });
    });
  });

  describe('TeachersFacade', () => {
    const listUseCase = { execute: vi.fn() };

    beforeEach(() => {
      listUseCase.execute.mockReset();
      listUseCase.execute.mockResolvedValue(emptyPage);
      TestBed.configureTestingModule({
        providers: [
          TeachersFacade,
          { provide: ListTeachersUseCase, useValue: listUseCase },
          { provide: ModerateTeacherProfileUseCase, useValue: noopUseCase },
        ],
      });
    });

    it('resets cursor on changeSort', async () => {
      const facade = TestBed.inject(TeachersFacade);
      await facade.loadList({});
      await facade.changeSort({}, { field: 'displayName', direction: 'asc' });

      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        {},
        expect.objectContaining({
          cursor: null,
          sort: { field: 'displayName', direction: 'asc' },
        }),
      );
    });
  });

  describe('SessionsFacade', () => {
    const listUseCase = { execute: vi.fn() };

    beforeEach(() => {
      listUseCase.execute.mockReset();
      listUseCase.execute.mockResolvedValue(emptyPage);
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
    });

    it('resets cursor on changeSort', async () => {
      const facade = TestBed.inject(SessionsFacade);
      await facade.loadList(sessionFilters);
      await facade.changeSort(sessionFilters, {
        field: 'createdAt',
        direction: 'asc',
      });

      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        sessionFilters,
        expect.objectContaining({
          cursor: null,
          sort: { field: 'createdAt', direction: 'asc' },
        }),
      );
    });
  });

  describe('SessionReportsFacade', () => {
    const listUseCase = { execute: vi.fn() };

    beforeEach(() => {
      listUseCase.execute.mockReset();
      listUseCase.execute.mockResolvedValue(emptyPage);
      TestBed.configureTestingModule({
        providers: [
          SessionReportsFacade,
          { provide: ListSessionReportsUseCase, useValue: listUseCase },
          { provide: GetSessionReportUseCase, useValue: noopUseCase },
        ],
      });
    });

    it('resets cursor on changeSort', async () => {
      const facade = TestBed.inject(SessionReportsFacade);
      await facade.loadList(reportFilters);
      await facade.changeSort(reportFilters, {
        field: 'updatedAt',
        direction: 'asc',
      });

      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        reportFilters,
        expect.objectContaining({
          cursor: null,
          sort: { field: 'updatedAt', direction: 'asc' },
        }),
      );
    });
  });

  describe('SessionDisputesFacade', () => {
    const listUseCase = { execute: vi.fn() };

    beforeEach(() => {
      listUseCase.execute.mockReset();
      listUseCase.execute.mockResolvedValue(emptyPage);
      TestBed.configureTestingModule({
        providers: [
          SessionDisputesFacade,
          { provide: ListSessionDisputesUseCase, useValue: listUseCase },
          { provide: GetSessionDisputeUseCase, useValue: noopUseCase },
          { provide: SESSION_READ_REPOSITORY, useValue: noopUseCase },
          {
            provide: QURAN_SESSIONS_USER_REPOSITORY,
            useValue: { getByIds: vi.fn(), getById: vi.fn() },
          },
        ],
      });
    });

    it('resets cursor on changeSort', async () => {
      const facade = TestBed.inject(SessionDisputesFacade);
      await facade.loadList({ status: null, search: null });
      await facade.changeSort(
        { status: null, search: null },
        { field: 'updatedAt', direction: 'asc' },
      );

      expect(listUseCase.execute).toHaveBeenLastCalledWith(
        { status: null, search: null },
        expect.objectContaining({
          cursor: null,
          sort: { field: 'updatedAt', direction: 'asc' },
        }),
      );
      expect(facade.sort()).toEqual({ field: 'updatedAt', direction: 'asc' });
    });
  });
});
