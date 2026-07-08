import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { SessionsFacade } from './sessions.facade';
import { ListAdminSessionsUseCase } from '../../domain/usecases/session.usecases';
import { GetAdminSessionUseCase } from '../../domain/usecases/session.usecases';
import { GetSessionTimelineUseCase } from '../../domain/usecases/session-audit.usecases';
import { ListSessionCompensationsUseCase } from '../../domain/usecases/session-audit.usecases';
import { GetCallTrackingSummaryUseCase } from '../../domain/usecases/call-tracking.usecases';
import { ListCallEventsUseCase } from '../../domain/usecases/call-tracking.usecases';
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
import {
  TEACHER_PROFILE_REPOSITORY,
  TeacherProfileRepository,
} from '../../domain/repositories/teacher-profile.repository';
import {
  QURAN_SESSIONS_USER_REPOSITORY,
  QuranSessionsUserRepository,
} from '../../domain/repositories/quran-sessions-user.repository';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import { TeacherVerificationStatus } from '../../domain/entities/teacher-profile.entity';
import { QuranSessionsAccountStatus } from '../../domain/entities/quran-sessions-user.entity';

describe('SessionsFacade — participants', () => {
  let facade: SessionsFacade;
  let teacherRepo: TeacherProfileRepository;
  let userRepo: QuranSessionsUserRepository;

  const session = {
    id: 'booking-1',
    aggregateId: 'agg-1',
    sessionId: 'session-1',
    studentId: 'student-1',
    teacherId: 'teacher-1',
    slotId: 'slot-1',
    startsAt: new Date(),
    endsAt: new Date(),
    lifecycleStatus: SessionLifecycleStatus.Scheduled,
    callType: 'agora',
    pricingType: 'free',
    countryCode: 'EG',
    cityId: 'cairo',
    paymentStatus: 'none',
    paymentReference: null,
    paymentProvider: 'none',
    priceAmount: 0,
    priceCurrency: 'USD',
    amountPaidUsd: 0,
    cancellationReason: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(() => {
    teacherRepo = {
      list: vi.fn(),
      getById: vi.fn().mockResolvedValue({
        id: 'teacher-1',
        userId: 'user-teacher',
        displayName: 'Ustad Ahmad',
        avatarUrl: null,
        publicBio: null,
        verificationStatus: TeacherVerificationStatus.Verified,
        teachingLanguages: [],
        specializations: [],
        averageRating: 0,
        reviewCount: 0,
        isActive: true,
        profileCompleteness: 'complete',
        isPubliclyVisible: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
      getByIds: vi.fn().mockResolvedValue(new Map()),
    };

    userRepo = {
      list: vi.fn(),
      listMatchingUserIds: vi.fn(),
      getByIds: vi.fn(),
      getById: vi.fn().mockImplementation(async (id: string) => {
        if (id === 'student-1') {
          return {
              userId: id,
              email: 's@example.com',
              displayName: 'Fatima',
              avatarUrl: null,
              gender: null,
              countryCode: 'EG',
              countryName: 'Egypt',
              cityId: 'cairo',
              cityName: 'Cairo',
              profileCompleted: true,
              accountStatus: QuranSessionsAccountStatus.Active,
              canApplyAsTeacher: true,
              createdAt: new Date(),
              updatedAt: new Date(),
          };
        }
        if (id === 'user-teacher') {
          return {
              userId: id,
              email: 't@example.com',
              displayName: 'Ustad Ahmad',
              avatarUrl: null,
              gender: null,
              countryCode: 'EG',
              countryName: 'Egypt',
              cityId: 'cairo',
              cityName: 'Cairo',
              profileCompleted: true,
              accountStatus: QuranSessionsAccountStatus.Active,
              canApplyAsTeacher: false,
              createdAt: new Date(),
              updatedAt: new Date(),
          };
        }
        return null;
      }),
    };

    TestBed.configureTestingModule({
      providers: [
        SessionsFacade,
        { provide: ListAdminSessionsUseCase, useValue: { execute: vi.fn() } },
        {
          provide: GetAdminSessionUseCase,
          useValue: { execute: vi.fn().mockResolvedValue(session) },
        },
        {
          provide: GetSessionTimelineUseCase,
          useValue: { execute: vi.fn().mockResolvedValue([]) },
        },
        {
          provide: ListSessionCompensationsUseCase,
          useValue: { execute: vi.fn().mockResolvedValue([]) },
        },
        {
          provide: GetCallTrackingSummaryUseCase,
          useValue: { execute: vi.fn().mockResolvedValue(null) },
        },
        {
          provide: ListCallEventsUseCase,
          useValue: { execute: vi.fn() },
        },
        { provide: CancelSessionUseCase, useValue: { execute: vi.fn() } },
        { provide: MarkSessionNoShowUseCase, useValue: { execute: vi.fn() } },
        { provide: CompleteSessionUseCase, useValue: { execute: vi.fn() } },
        {
          provide: IssueSessionCompensationUseCase,
          useValue: { execute: vi.fn() },
        },
        {
          provide: ConfirmSessionRescheduleUseCase,
          useValue: { execute: vi.fn() },
        },
        { provide: ApproveSessionRefundUseCase, useValue: { execute: vi.fn() } },
        {
          provide: ConfirmManualBookingPaymentUseCase,
          useValue: { execute: vi.fn() },
        },
        {
          provide: RejectManualBookingPaymentUseCase,
          useValue: { execute: vi.fn() },
        },
        { provide: TEACHER_PROFILE_REPOSITORY, useValue: teacherRepo },
        { provide: QURAN_SESSIONS_USER_REPOSITORY, useValue: userRepo },
      ],
    });

    facade = TestBed.inject(SessionsFacade);
  });

  it('fetches teacher profile and users by id only', async () => {
    await facade.loadDetail('booking-1');

    expect(teacherRepo.getById).toHaveBeenCalledWith('teacher-1');
    expect(teacherRepo.list).not.toHaveBeenCalled();
    expect(userRepo.getById).toHaveBeenCalledWith('student-1');
    expect(userRepo.getById).toHaveBeenCalledWith('user-teacher');
    expect(userRepo.getByIds).not.toHaveBeenCalled();
    expect(userRepo.list).not.toHaveBeenCalled();
  });

  it('does not load raw call events on detail load (lazy, panel-triggered only)', async () => {
    const callEventsUseCase = TestBed.inject(ListCallEventsUseCase);
    await facade.loadDetail('booking-1');

    expect(callEventsUseCase.execute).not.toHaveBeenCalled();
  });

  it('loads raw call events only on explicit loadCallEvents', async () => {
    const callEventsUseCase = TestBed.inject(ListCallEventsUseCase) as unknown as {
      execute: ReturnType<typeof vi.fn>;
    };
    callEventsUseCase.execute.mockResolvedValue({
      items: [],
      nextCursor: null,
      hasMore: false,
    });

    await facade.loadDetail('booking-1');
    expect(callEventsUseCase.execute).not.toHaveBeenCalled();

    await facade.loadCallEvents();
    expect(callEventsUseCase.execute).toHaveBeenCalledTimes(1);
    expect(callEventsUseCase.execute).toHaveBeenCalledWith(
      'session-1',
      expect.objectContaining({ pageSize: 20, cursor: null }),
    );
  });

  it('exposes participant view models on the detail load', async () => {
    await facade.loadDetail('booking-1');
    await vi.waitFor(() => {
      expect(facade.isParticipantsLoading()).toBe(false);
    });

    const participants = facade.sessionParticipants();
    expect(participants?.teacher.displayName).toBe('Ustad Ahmad');
    expect(participants?.student.displayName).toBe('Fatima');
    expect(participants?.teacher.matchesSession).toBe(true);
    expect(participants?.student.matchesSession).toBe(true);
  });

  it('renders critical detail data before participant profiles load', async () => {
    const resolvers: Array<(u: unknown) => void> = [];
    userRepo.getById = vi.fn().mockImplementation(
      () =>
        new Promise<unknown>((resolve) => {
          resolvers.push(resolve);
        }),
    );

    const detailPromise = facade.loadDetail('booking-1');

    // Wait for the critical phase to complete (detail state = success) using
    // polling — the Promise.all inside loadDetail needs several microtask
    // ticks to resolve. The participant fetch is intentionally blocked.
    await vi.waitFor(() => {
      expect(facade.detailLoadState()).toBe('success');
    });

    // Critical data is already rendered — detail, timeline, call tracking.
    expect(facade.detail()).not.toBeNull();
    expect(facade.detail()?.id).toBe('booking-1');
    expect(facade.callTrackingSummary()).toBeNull();

    // Participants are still loading (secondary phase).
    expect(facade.isParticipantsLoading()).toBe(true);
    expect(facade.sessionParticipants()).toBeNull();

    // Now resolve the slow user fetch
    resolvers.forEach(r => r(null));
    await vi.waitFor(() => {
      expect(facade.isParticipantsLoading()).toBe(false);
    });

    expect(facade.isParticipantsLoading()).toBe(false);
    expect(facade.sessionParticipants()).not.toBeNull();
  });

  it('missing call tracking does not block session detail', async () => {
    // callSummaryUseCase already returns null in beforeEach — verify detail renders.
    await facade.loadDetail('booking-1');
    await vi.waitFor(() => {
      expect(facade.isParticipantsLoading()).toBe(false);
    });

    expect(facade.detailLoadState()).toBe('success');
    expect(facade.detail()).not.toBeNull();
    expect(facade.callTrackingSummary()).toBeNull();
    expect(facade.sessionParticipants()).not.toBeNull();
  });
});
