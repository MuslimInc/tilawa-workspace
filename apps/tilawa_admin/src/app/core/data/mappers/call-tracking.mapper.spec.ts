import { describe, it, expect } from 'vitest';

import { CallTrackingMapper } from './call-tracking.mapper';

const SCHEDULED_MS = Date.UTC(2026, 5, 24, 12, 0, 0);

describe('CallTrackingMapper.summaryFromFirestore', () => {
  it('maps a full summary dto with Timestamp-like values', () => {
    const summary = CallTrackingMapper.summaryFromFirestore('session-1', {
      scheduledStartsAt: { toDate: () => new Date(SCHEDULED_MS) },
      firstJoinRole: 'teacher',
      firstJoinAt: { toDate: () => new Date(SCHEDULED_MS + 60_000) },
      secondJoinRole: 'student',
      secondJoinAt: { toDate: () => new Date(SCHEDULED_MS + 120_000) },
      actualCallStartedAt: { toDate: () => new Date(SCHEDULED_MS + 120_000) },
      callEndedAt: { toDate: () => new Date(SCHEDULED_MS + 1_800_000) },
      teacherLate: false,
      studentLate: true,
      lateGraceMinutes: 5,
      teacherNoShow: false,
      studentNoShow: false,
      noShowWindowMinutes: 15,
      bothParticipantsConnectedSeconds: 1680,
      reconnectCount: 2,
      interruptionCount: 1,
      updatedAt: { toDate: () => new Date(SCHEDULED_MS + 1_800_000) },
    });

    expect(summary.sessionId).toBe('session-1');
    expect(summary.firstJoinRole).toBe('teacher');
    expect(summary.studentLate).toBe(true);
    expect(summary.bothParticipantsConnectedSeconds).toBe(1680);
    expect(summary.interruptionCount).toBe(1);
    expect(summary.scheduledStartsAt?.getTime()).toBe(SCHEDULED_MS);
  });

  it('defaults missing fields without fabricating late/no-show', () => {
    const summary = CallTrackingMapper.summaryFromFirestore('session-2', {});

    expect(summary.sessionId).toBe('session-2');
    expect(summary.teacherLate).toBeNull();
    expect(summary.studentLate).toBeNull();
    expect(summary.teacherNoShow).toBe(false);
    expect(summary.studentNoShow).toBe(false);
    expect(summary.bothParticipantsConnectedSeconds).toBe(0);
    expect(summary.reconnectCount).toBe(0);
    expect(summary.interruptionCount).toBe(0);
    expect(summary.scheduledStartsAt).toBeNull();
  });
});

describe('CallTrackingMapper.eventFromFirestore', () => {
  it('maps a raw event dto', () => {
    const event = CallTrackingMapper.eventFromFirestore('evt-1', {
      eventType: 'joinSucceeded',
      actorRole: 'student',
      actorId: 'uid-1',
      networkQuality: 'good',
      recordedAt: { toDate: () => new Date(SCHEDULED_MS) },
      clientTimestampMs: SCHEDULED_MS,
    });

    expect(event.id).toBe('evt-1');
    expect(event.eventType).toBe('joinSucceeded');
    expect(event.actorRole).toBe('student');
    expect(event.networkQuality).toBe('good');
    expect(event.recordedAt?.getTime()).toBe(SCHEDULED_MS);
  });

  it('falls back for an empty event dto', () => {
    const event = CallTrackingMapper.eventFromFirestore('evt-2', {});
    expect(event.eventType).toBe('unknown');
    expect(event.actorRole).toBe('system');
    expect(event.reasonCode).toBeNull();
    expect(event.recordedAt).toBeNull();
  });
});
