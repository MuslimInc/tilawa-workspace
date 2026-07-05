import { describe, it, expect, beforeEach, vi } from 'vitest';
import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { ActivatedRoute } from '@angular/router';

import { SessionDetailComponent } from './session-detail.component';
import { SessionsFacade } from '../../../core/application/facades/sessions.facade';
import { I18nService } from '../../../core/i18n/i18n.service';
import {
  AdminSessionDetailVm,
  CallEventVm,
  CallTrackingVm,
  SessionParticipantsVm,
} from '../../../core/data/view-models/quran-sessions.view-model';

function detailVm(overrides: Partial<AdminSessionDetailVm> = {}): AdminSessionDetailVm {
  return {
    id: 'booking-1',
    aggregateId: 'agg-1',
    sessionId: 'session-1',
    studentId: 'student-1',
    teacherId: 'teacher-1',
    slotId: 'slot-1',
    startsAt: new Date('2026-06-24T12:00:00Z'),
    endsAt: new Date('2026-06-24T12:30:00Z'),
    lifecycleStatus: 'completed',
    callType: 'agora',
    pricingType: 'free',
    countryCode: 'EG',
    cityId: 'cairo',
    paymentStatus: 'none',
    amountPaidUsd: '0.00',
    cancellationReason: null,
    createdAt: new Date('2026-06-20T12:00:00Z'),
    updatedAt: new Date('2026-06-24T12:30:00Z'),
    ...overrides,
  };
}

function callVm(overrides: Partial<CallTrackingVm> = {}): CallTrackingVm {
  return {
    whoJoinedFirst: 'teacher',
    teacherJoinedAt: new Date('2026-06-24T12:01:00Z'),
    studentJoinedAt: new Date('2026-06-24T12:08:00Z'),
    teacherLate: false,
    studentLate: true,
    teacherDelayMinutes: 1,
    studentDelayMinutes: 8,
    actualCallStartedAt: new Date('2026-06-24T12:08:00Z'),
    actualCallEndedAt: new Date('2026-06-24T12:38:00Z'),
    connectedSeconds: 1800,
    connectedMinutes: 30,
    reconnectCount: 2,
    interruptionCount: 1,
    teacherNoShow: false,
    studentNoShow: false,
    providerType: 'agora',
    updatedAt: null,
    ...overrides,
  };
}

function participantsVm(overrides: Partial<SessionParticipantsVm> = {}): SessionParticipantsVm {
  return {
    teacher: {
      loadState: 'loaded',
      teacherId: 'teacher-1',
      userId: 'user-teacher',
      displayName: 'Ustad Ahmad',
      verificationStatus: 'verified',
      profileCompleteness: 'complete',
      isActive: true,
      isPubliclyVisible: true,
      accountStatus: 'active',
      matchesSession: true,
      sessionJoinStatus: 'joined',
      ...overrides.teacher,
    },
    student: {
      loadState: 'loaded',
      studentId: 'student-1',
      displayName: 'Fatima',
      email: 'fatima@example.com',
      accountStatus: 'active',
      profileCompleted: true,
      canApplyAsTeacher: true,
      matchesSession: true,
      sessionJoinStatus: 'not_joined_yet',
      ...overrides.student,
    },
    callPhase: 'waiting',
    ...overrides,
  };
}

/** Minimal signal-backed stand-in for the facade surface the component reads. */
function makeFakeFacade() {
  const detail = signal<AdminSessionDetailVm | null>(detailVm());
  const detailLoadState = signal<'idle' | 'loading' | 'success' | 'error'>('success');
  const callTrackingSummary = signal<CallTrackingVm | null>(callVm());
  const callEvents = signal<CallEventVm[]>([]);
  const callEventsLoadState = signal<'idle' | 'loading' | 'success' | 'error'>('idle');
  const canLoadMoreCallEvents = signal(false);
  const sessionParticipants = signal<SessionParticipantsVm | null>(participantsVm());

  return {
    // signals the component aliases
    detail,
    detailLoadState,
    detailErrorMessage: signal<string | null>(null),
    timelineEvents: signal([]),
    compensationHistory: signal([]),
    callTrackingSummary,
    callEvents,
    callEventsLoadState,
    canLoadMoreCallEvents,
    sessionParticipants,
    isActionLoading: signal(false),
    // spied methods
    loadDetail: vi.fn().mockResolvedValue(undefined),
    loadCallEvents: vi.fn().mockResolvedValue(undefined),
    loadMoreCallEvents: vi.fn().mockResolvedValue(undefined),
  };
}

type FakeFacade = ReturnType<typeof makeFakeFacade>;

describe('SessionDetailComponent — call tracking', () => {
  let facade: FakeFacade;
  let fixture: ComponentFixture<SessionDetailComponent>;

  beforeEach(async () => {
    facade = makeFakeFacade();

    await TestBed.configureTestingModule({
      imports: [SessionDetailComponent],
      providers: [
        provideRouter([]),
        { provide: SessionsFacade, useValue: facade },
        {
          provide: I18nService,
          useValue: {
            language: signal('en'),
            ready: signal(true),
            t: (key: string) => key,
          },
        },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: { get: () => 'booking-1' } } },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(SessionDetailComponent);
    fixture.detectChanges();
  });

  function text(): string {
    return fixture.nativeElement.textContent as string;
  }

  it('loads the detail (and its aggregated summary) on init', () => {
    expect(facade.loadDetail).toHaveBeenCalledWith('booking-1');
  });

  it('renders teacher and student participant info', () => {
    const body = text();
    expect(body).toContain('sessionDetail_participants');
    expect(body).toContain('Ustad Ahmad');
    expect(body).toContain('Fatima');
    expect(body).toContain('teacher-1');
    expect(body).toContain('student-1');
  });

  it('shows warning when teacher profile is missing', () => {
    facade.sessionParticipants.set(
      participantsVm({
        teacher: {
          loadState: 'not_found',
          teacherId: 'teacher-1',
          userId: null,
          displayName: null,
          verificationStatus: null,
          profileCompleteness: null,
          isActive: null,
          isPubliclyVisible: null,
          accountStatus: null,
          matchesSession: false,
          sessionJoinStatus: 'not_available',
        },
      }),
    );
    fixture.detectChanges();
    expect(text()).toContain('sessionDetail_teacherNotFound');
  });

  it('shows warning when student profile is missing', () => {
    facade.sessionParticipants.set(
      participantsVm({
        student: {
          loadState: 'not_found',
          studentId: 'student-1',
          displayName: null,
          email: null,
          accountStatus: null,
          profileCompleted: null,
          canApplyAsTeacher: null,
          matchesSession: false,
          sessionJoinStatus: 'not_available',
        },
      }),
    );
    fixture.detectChanges();
    expect(text()).toContain('sessionDetail_studentNotFound');
  });

  it('shows suspended teacher and blocked student statuses', () => {
    facade.sessionParticipants.set(
      participantsVm({
        teacher: {
          loadState: 'loaded',
          teacherId: 'teacher-1',
          userId: 'user-teacher',
          displayName: 'Suspended Teacher',
          verificationStatus: 'verified',
          profileCompleteness: 'complete',
          isActive: false,
          isPubliclyVisible: false,
          accountStatus: 'suspended',
          matchesSession: true,
          sessionJoinStatus: 'no_show',
        },
        student: {
          loadState: 'loaded',
          studentId: 'student-1',
          displayName: 'Blocked Student',
          email: 'b@example.com',
          accountStatus: 'blocked',
          profileCompleted: true,
          canApplyAsTeacher: false,
          matchesSession: true,
          sessionJoinStatus: 'did_not_join',
        },
      }),
    );
    fixture.detectChanges();
    const body = text();
    expect(body).toContain('Suspended Teacher');
    expect(body).toContain('Blocked Student');
    expect(body).toContain('status_suspended');
    expect(body).toContain('status_blocked');
    expect(body).toContain('status_no_show');
  });

  it('renders participant account links', () => {
    const links = fixture.nativeElement.querySelectorAll('a[href]');
    const hrefs = [...links].map((a: HTMLAnchorElement) => a.getAttribute('href'));
    expect(hrefs).toContain('/quran-sessions/wallets/user-teacher');
    expect(hrefs).toContain('/quran-sessions/wallets/student-1');
  });

  it('renders the aggregated call-tracking metrics', () => {
    const body = text();
    // headline metrics surfaced from the single aggregated summary doc
    expect(body).toContain('sessionDetail_callTracking');
    expect(body).toContain('30'); // connected minutes
    expect(body).toContain('1800'); // connected seconds
    expect(body).toContain('2'); // reconnect count
    expect(body).toContain('agora'); // provider
    // late + delay
    expect(body).toContain('callTracking_studentLate');
    expect(body).toContain('8'); // student delay minutes
  });

  it('shows the empty state when no call tracking exists', () => {
    facade.callTrackingSummary.set(null);
    fixture.detectChanges();
    expect(text()).toContain('callTracking_noData');
  });

  it('does NOT read raw events until the panel is opened (lazy)', () => {
    expect(facade.loadCallEvents).not.toHaveBeenCalled();
    // table header should not be present yet
    expect(text()).not.toContain('callTracking_recordedAt');
  });

  it('lazily loads raw events when the panel is toggled open', async () => {
    fixture.componentInstance.toggleEventsPanel();
    expect(facade.loadCallEvents).toHaveBeenCalledTimes(1);

    facade.callEvents.set([
      {
        id: 'evt-1',
        eventType: 'joinSucceeded',
        actorRole: 'teacher',
        detail: 'good',
        recordedAt: new Date('2026-06-24T12:01:00Z'),
      },
    ]);
    facade.callEventsLoadState.set('success');
    fixture.detectChanges();

    const body = text();
    expect(body).toContain('callTracking_recordedAt');
    expect(body).toContain('joinSucceeded');
  });

  it('renders a Load more control only when more pages exist', () => {
    fixture.componentInstance.toggleEventsPanel();
    facade.callEvents.set([
      {
        id: 'evt-1',
        eventType: 'leave',
        actorRole: 'student',
        detail: '—',
        recordedAt: new Date('2026-06-24T12:10:00Z'),
      },
    ]);
    facade.callEventsLoadState.set('success');
    facade.canLoadMoreCallEvents.set(true);
    fixture.detectChanges();

    expect(text()).toContain('common_loadMore');

    fixture.componentInstance.loadMoreCallEvents();
    expect(facade.loadMoreCallEvents).toHaveBeenCalledTimes(1);
  });
});
