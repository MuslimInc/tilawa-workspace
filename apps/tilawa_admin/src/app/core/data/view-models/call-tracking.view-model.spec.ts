import { describe, it, expect } from 'vitest';

import { QuranSessionsViewModelMapper } from './quran-sessions.view-model';
import { CallTrackingSummary, CallEvent } from '../../domain/entities/call-tracking.entity';

const SCHEDULED = new Date(Date.UTC(2026, 5, 24, 12, 0, 0));

function summary(overrides: Partial<CallTrackingSummary> = {}): CallTrackingSummary {
  return {
    sessionId: 'session-1',
    scheduledStartsAt: SCHEDULED,
    firstJoinRole: 'teacher',
    firstJoinAt: new Date(SCHEDULED.getTime() + 60_000),
    secondJoinRole: 'student',
    secondJoinAt: new Date(SCHEDULED.getTime() + 8 * 60_000),
    actualCallStartedAt: new Date(SCHEDULED.getTime() + 8 * 60_000),
    callEndedAt: new Date(SCHEDULED.getTime() + 38 * 60_000),
    teacherLate: false,
    studentLate: true,
    lateGraceMinutes: 5,
    teacherNoShow: false,
    studentNoShow: false,
    noShowWindowMinutes: 15,
    bothParticipantsConnectedSeconds: 1800,
    reconnectCount: 1,
    interruptionCount: 1,
    updatedAt: null,
    ...overrides,
  };
}

describe('QuranSessionsViewModelMapper.toCallTracking', () => {
  it('resolves per-role join times from the role-tagged joins', () => {
    const vm = QuranSessionsViewModelMapper.toCallTracking(summary(), 'agora');

    expect(vm.whoJoinedFirst).toBe('teacher');
    expect(vm.teacherJoinedAt?.getTime()).toBe(SCHEDULED.getTime() + 60_000);
    expect(vm.studentJoinedAt?.getTime()).toBe(SCHEDULED.getTime() + 8 * 60_000);
    expect(vm.providerType).toBe('agora');
  });

  it('derives clamped per-role delay minutes from the scheduled start', () => {
    const vm = QuranSessionsViewModelMapper.toCallTracking(summary(), 'agora');

    // Teacher joined 1 min after start, student 8 min after.
    expect(vm.teacherDelayMinutes).toBe(1);
    expect(vm.studentDelayMinutes).toBe(8);
  });

  it('clamps an early join to zero delay and converts duration to minutes', () => {
    const vm = QuranSessionsViewModelMapper.toCallTracking(
      summary({
        firstJoinAt: new Date(SCHEDULED.getTime() - 30_000), // joined early
        bothParticipantsConnectedSeconds: 125,
      }),
      'externalMeeting',
    );

    expect(vm.teacherDelayMinutes).toBe(0);
    expect(vm.connectedSeconds).toBe(125);
    expect(vm.connectedMinutes).toBe(2);
  });

  it('returns null delay when join time or schedule is missing', () => {
    const vm = QuranSessionsViewModelMapper.toCallTracking(
      summary({
        secondJoinRole: null,
        secondJoinAt: null,
        scheduledStartsAt: null,
      }),
      'agora',
    );

    expect(vm.studentJoinedAt).toBeNull();
    expect(vm.studentDelayMinutes).toBeNull();
    expect(vm.teacherDelayMinutes).toBeNull();
  });

  it('never reports negative connected duration', () => {
    const vm = QuranSessionsViewModelMapper.toCallTracking(
      summary({ bothParticipantsConnectedSeconds: -50 }),
      'agora',
    );
    expect(vm.connectedSeconds).toBe(0);
    expect(vm.connectedMinutes).toBe(0);
  });
});

describe('QuranSessionsViewModelMapper.toCallEvent', () => {
  function event(overrides: Partial<CallEvent> = {}): CallEvent {
    return {
      id: 'evt-1',
      eventType: 'joinFailed',
      actorRole: 'student',
      actorId: 'uid-1',
      reasonCode: 'permission_denied',
      networkQuality: 'poor',
      remoteParticipantId: null,
      recordedAt: SCHEDULED,
      clientTimestampMs: SCHEDULED.getTime(),
      ...overrides,
    };
  }

  it('joins reason and network quality into a detail string', () => {
    const vm = QuranSessionsViewModelMapper.toCallEvent(event());
    expect(vm.detail).toBe('permission_denied · poor');
  });

  it('falls back to a dash when no detail parts exist', () => {
    const vm = QuranSessionsViewModelMapper.toCallEvent(
      event({ reasonCode: null, networkQuality: null }),
    );
    expect(vm.detail).toBe('—');
    expect(vm.eventType).toBe('joinFailed');
  });
});
