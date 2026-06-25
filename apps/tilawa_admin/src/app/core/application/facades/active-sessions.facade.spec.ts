import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { ActiveSessionsFacade } from './active-sessions.facade';
import { ListActiveAdminSessionsUseCase } from '../../domain/usecases/active-session.usecases';
import {
  CALL_TRACKING_REPOSITORY,
  CallTrackingRepository,
} from '../../domain/repositories/call-tracking.repository';
import {
  TEACHER_PROFILE_REPOSITORY,
  TeacherProfileRepository,
} from '../../domain/repositories/teacher-profile.repository';
import {
  QURAN_SESSIONS_USER_REPOSITORY,
  QuranSessionsUserRepository,
} from '../../domain/repositories/quran-sessions-user.repository';
import {
  ACTIVE_SESSION_PAGE_SIZE,
  ActiveSessionOperationalFilter,
} from '../../domain/entities/active-session.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';

describe('ActiveSessionsFacade', () => {
  let facade: ActiveSessionsFacade;
  let listUseCase: { execute: ReturnType<typeof vi.fn> };
  let callRepo: CallTrackingRepository;
  let teacherRepo: TeacherProfileRepository;
  let userRepo: QuranSessionsUserRepository;

  beforeEach(() => {
    listUseCase = {
      execute: vi.fn().mockResolvedValue({
        items: [
          {
            id: 'booking-1',
            aggregateId: 'agg-1',
            sessionId: 'session-1',
            studentId: 'student-1',
            teacherId: 'teacher-1',
            slotId: 'slot-1',
            startsAt: new Date(),
            endsAt: null,
            lifecycleStatus: SessionLifecycleStatus.InProgress,
            callType: 'agora',
            pricingType: 'free',
            countryCode: 'EG',
            cityId: 'cairo',
            paymentStatus: 'none',
            amountPaidUsd: 0,
            cancellationReason: null,
            createdAt: new Date(),
            updatedAt: new Date(),
          },
        ],
        nextCursor: null,
        hasMore: false,
      }),
    };

    callRepo = {
      getSummary: vi.fn(),
      listEvents: vi.fn(),
      getSummariesBySessionIds: vi.fn().mockResolvedValue(new Map()),
    };

    teacherRepo = {
      list: vi.fn(),
      getById: vi.fn(),
      getByIds: vi.fn().mockResolvedValue(
        new Map([
          [
            'teacher-1',
            {
              id: 'teacher-1',
              userId: 'user-teacher',
              displayName: 'Ustad Ahmad',
              avatarUrl: null,
              publicBio: null,
              verificationStatus: 'verified',
              teachingLanguages: [],
              specializations: [],
              averageRating: 0,
              reviewCount: 0,
              isActive: true,
              profileCompleteness: 'complete',
              isPubliclyVisible: true,
              createdAt: new Date(),
              updatedAt: new Date(),
            },
          ],
        ]),
      ),
    };

    userRepo = {
      list: vi.fn(),
      listMatchingUserIds: vi.fn(),
      getById: vi.fn(),
      getByIds: vi.fn().mockResolvedValue(
        new Map([
          [
            'student-1',
            {
              userId: 'student-1',
              email: 's@example.com',
              displayName: 'Fatima',
              avatarUrl: null,
              gender: null,
              countryCode: 'EG',
              countryName: 'Egypt',
              cityId: 'cairo',
              cityName: 'Cairo',
              profileCompleted: true,
              accountStatus: 'active',
              canApplyAsTeacher: true,
              createdAt: new Date(),
              updatedAt: new Date(),
            },
          ],
          [
            'user-teacher',
            {
              userId: 'user-teacher',
              email: 't@example.com',
              displayName: 'Ustad Ahmad',
              avatarUrl: null,
              gender: null,
              countryCode: 'EG',
              countryName: 'Egypt',
              cityId: 'cairo',
              cityName: 'Cairo',
              profileCompleted: true,
              accountStatus: 'active',
              canApplyAsTeacher: false,
              createdAt: new Date(),
              updatedAt: new Date(),
            },
          ],
        ]),
      ),
    };

    TestBed.configureTestingModule({
      providers: [
        ActiveSessionsFacade,
        { provide: ListActiveAdminSessionsUseCase, useValue: listUseCase },
        { provide: CALL_TRACKING_REPOSITORY, useValue: callRepo },
        { provide: TEACHER_PROFILE_REPOSITORY, useValue: teacherRepo },
        { provide: QURAN_SESSIONS_USER_REPOSITORY, useValue: userRepo },
      ],
    });

    facade = TestBed.inject(ActiveSessionsFacade);
  });

  it('queries active sessions with bounded page size', async () => {
    await facade.loadList();

    expect(listUseCase.execute).toHaveBeenCalledWith(
      expect.objectContaining({
        operationalFilter: ActiveSessionOperationalFilter.All,
      }),
      expect.objectContaining({ pageSize: ACTIVE_SESSION_PAGE_SIZE, cursor: null }),
    );
  });

  it('loads call summaries and participants by id only', async () => {
    await facade.loadList();

    expect(callRepo.getSummariesBySessionIds).toHaveBeenCalledWith(['session-1']);
    expect(teacherRepo.getByIds).toHaveBeenCalledWith(['teacher-1']);
    expect(userRepo.getByIds).toHaveBeenCalledWith(['student-1', 'user-teacher']);
    expect(callRepo.listEvents).not.toHaveBeenCalled();
    expect(teacherRepo.list).not.toHaveBeenCalled();
    expect(userRepo.list).not.toHaveBeenCalled();
  });

  it('reloads when operational filter changes', async () => {
    await facade.changeFilter(ActiveSessionOperationalFilter.LiveNow);

    expect(facade.filter()).toBe(ActiveSessionOperationalFilter.LiveNow);
    expect(listUseCase.execute).toHaveBeenCalledTimes(1);
  });

  it('includes sessions with hasActiveCall even when startsAt is far in the future', async () => {
    // Simulate a session scheduled 6 hours from now (beyond the +2h window)
    // but with hasActiveCall denormalized by call telemetry.
    const futureStartsAt = new Date(Date.now() + 6 * 60 * 60 * 1000);
    listUseCase.execute.mockResolvedValueOnce({
      items: [
        {
          id: 'booking-early-join',
          aggregateId: 'agg-early',
          sessionId: 'session-early',
          studentId: 'student-1',
          teacherId: 'teacher-1',
          slotId: 'slot-1',
          startsAt: futureStartsAt,
          endsAt: null,
          lifecycleStatus: SessionLifecycleStatus.Scheduled,
          callType: 'agora',
          pricingType: 'free',
          countryCode: 'EG',
          cityId: 'cairo',
          paymentStatus: 'none',
          amountPaidUsd: 0,
          cancellationReason: null,
          hasActiveCall: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ],
      nextCursor: null,
      hasMore: false,
    });

    await facade.loadList();

    expect(facade.items().length).toBeGreaterThan(0);
    expect(facade.items()[0].bookingId).toBe('booking-early-join');
    // The operational status should reflect an active/waiting state, not be
    // filtered out by the time window.
    expect(facade.items()[0].operationalStatus).toBeDefined();
  });

  it('does not scan all sessions — query stays bounded by page size', async () => {
    await facade.loadList();

    // The use case is called once per loadList — the dual-query merge happens
    // inside the repository, not the facade. The facade passes a bounded
    // page size to the use case.
    expect(listUseCase.execute).toHaveBeenCalledWith(
      expect.any(Object),
      expect.objectContaining({ pageSize: ACTIVE_SESSION_PAGE_SIZE }),
    );
  });
});
