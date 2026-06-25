import { describe, it, expect } from 'vitest';

import {
  deriveActiveSessionOperationalStatus,
  enrichActiveSessionRow,
} from './active-session.mapper';
import {
  ActiveSessionOperationalStatus,
  matchesOperationalFilter,
  ActiveSessionOperationalFilter,
  resolveActiveSessionWindow,
} from '../../domain/entities/active-session.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import { CallTrackingSummary } from '../../domain/entities/call-tracking.entity';
import { buildActiveSessionQueryConstraints } from '../repositories/firebase-session-read.repository';

function summary(overrides: Partial<CallTrackingSummary> = {}): CallTrackingSummary {
  return {
    sessionId: 'session-1',
    scheduledStartsAt: new Date('2026-06-25T12:00:00Z'),
    firstJoinRole: null,
    firstJoinAt: null,
    secondJoinRole: null,
    secondJoinAt: null,
    actualCallStartedAt: null,
    callEndedAt: null,
    teacherLate: false,
    studentLate: false,
    lateGraceMinutes: 5,
    teacherNoShow: false,
    studentNoShow: false,
    noShowWindowMinutes: 15,
    bothParticipantsConnectedSeconds: 0,
    reconnectCount: 0,
    interruptionCount: 0,
    updatedAt: null,
    ...overrides,
  };
}

describe('deriveActiveSessionOperationalStatus', () => {
  const now = new Date('2026-06-25T12:10:00Z');

  it('maps waiting for teacher when only student joined', () => {
    expect(
      deriveActiveSessionOperationalStatus(
        {
          lifecycleStatus: SessionLifecycleStatus.Scheduled,
          startsAt: new Date('2026-06-25T12:00:00Z'),
          endsAt: new Date('2026-06-25T12:30:00Z'),
        },
        summary({
          firstJoinRole: 'student',
          firstJoinAt: new Date('2026-06-25T12:02:00Z'),
        }),
        now,
      ),
    ).toBe(ActiveSessionOperationalStatus.WaitingForTeacher);
  });

  it('maps waiting for student when only teacher joined', () => {
    expect(
      deriveActiveSessionOperationalStatus(
        {
          lifecycleStatus: SessionLifecycleStatus.Scheduled,
          startsAt: new Date('2026-06-25T12:00:00Z'),
          endsAt: null,
        },
        summary({
          firstJoinRole: 'teacher',
          firstJoinAt: new Date('2026-06-25T12:01:00Z'),
        }),
        now,
      ),
    ).toBe(ActiveSessionOperationalStatus.WaitingForStudent);
  });

  it('maps live session when call started', () => {
    expect(
      deriveActiveSessionOperationalStatus(
        {
          lifecycleStatus: SessionLifecycleStatus.InProgress,
          startsAt: new Date('2026-06-25T12:00:00Z'),
          endsAt: null,
        },
        summary({
          actualCallStartedAt: new Date('2026-06-25T12:05:00Z'),
        }),
        now,
      ),
    ).toBe(ActiveSessionOperationalStatus.Live);
  });

  it('maps interrupted when reconnecting during live call', () => {
    expect(
      deriveActiveSessionOperationalStatus(
        {
          lifecycleStatus: SessionLifecycleStatus.InProgress,
          startsAt: new Date('2026-06-25T12:00:00Z'),
          endsAt: null,
        },
        summary({
          actualCallStartedAt: new Date('2026-06-25T12:05:00Z'),
          reconnectCount: 2,
        }),
        now,
      ),
    ).toBe(ActiveSessionOperationalStatus.InterruptedReconnecting);
  });

  it('maps no-show candidate from summary flags', () => {
    expect(
      deriveActiveSessionOperationalStatus(
        {
          lifecycleStatus: SessionLifecycleStatus.Scheduled,
          startsAt: new Date('2026-06-25T12:00:00Z'),
          endsAt: null,
        },
        summary({ teacherNoShow: true }),
        now,
      ),
    ).toBe(ActiveSessionOperationalStatus.NoShowCandidate);
  });

  it('maps recently ended from call end timestamp', () => {
    expect(
      deriveActiveSessionOperationalStatus(
        {
          lifecycleStatus: SessionLifecycleStatus.Completed,
          startsAt: new Date('2026-06-25T11:30:00Z'),
          endsAt: new Date('2026-06-25T12:00:00Z'),
        },
        summary({ callEndedAt: new Date('2026-06-25T12:00:00Z') }),
        now,
      ),
    ).toBe(ActiveSessionOperationalStatus.RecentlyEnded);
  });

  it('falls back when call tracking summary is missing', () => {
    expect(
      deriveActiveSessionOperationalStatus(
        {
          lifecycleStatus: SessionLifecycleStatus.Scheduled,
          startsAt: new Date('2026-06-25T12:20:00Z'),
          endsAt: null,
        },
        null,
        now,
      ),
    ).toBe(ActiveSessionOperationalStatus.ScheduledStartingSoon);
  });
});

describe('matchesOperationalFilter', () => {
  it('matches late/no-show tab for late flags', () => {
    expect(
      matchesOperationalFilter(
        ActiveSessionOperationalStatus.Live,
        ActiveSessionOperationalFilter.LateNoShow,
        { teacherLate: true, studentLate: false },
      ),
    ).toBe(true);
  });
});

describe('buildActiveSessionQueryConstraints', () => {
  it('uses server-side lifecycle in-filter and startsAt window', () => {
    const now = new Date('2026-06-25T12:00:00Z');
    const window = resolveActiveSessionWindow(now);
    const constraints = buildActiveSessionQueryConstraints(window);

    expect(constraints).toHaveLength(3);
    expect(window.startsFrom.getTime()).toBeLessThan(window.startsTo.getTime());
  });

  it('window covers a live session that started more than 30 minutes ago', () => {
    const now = new Date('2026-06-25T12:00:00Z');
    const window = resolveActiveSessionWindow(now);

    // A session that started 90 minutes ago and is still in_progress.
    const liveSessionStartsAt = new Date('2026-06-25T10:30:00Z');
    expect(liveSessionStartsAt.getTime()).toBeGreaterThanOrEqual(window.startsFrom.getTime());
    expect(liveSessionStartsAt.getTime()).toBeLessThanOrEqual(window.startsTo.getTime());
  });

  it('window back-look is 4 hours (not the old 30 minutes)', () => {
    const now = new Date('2026-06-25T12:00:00Z');
    const window = resolveActiveSessionWindow(now);
    const backMs = now.getTime() - window.startsFrom.getTime();

    // 4 hours = 240 minutes = well over the old 30-minute back-window.
    expect(backMs).toBe(4 * 60 * 60 * 1000);
  });
});

describe('enrichActiveSessionRow', () => {
  it('includes reconnect and interruption counts from summary', () => {
    const row = enrichActiveSessionRow(
      {
        id: 'booking-1',
        aggregateId: 'agg-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        teacherId: 'teacher-1',
        slotId: 'slot-1',
        startsAt: new Date('2026-06-25T12:00:00Z'),
        endsAt: null,
        lifecycleStatus: SessionLifecycleStatus.InProgress,
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
      summary({ reconnectCount: 3, interruptionCount: 1 }),
    );

    expect(row.reconnectCount).toBe(3);
    expect(row.interruptionCount).toBe(1);
  });
});
