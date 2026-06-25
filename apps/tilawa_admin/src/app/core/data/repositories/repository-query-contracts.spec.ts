import { describe, expect, it } from 'vitest';
import { QueryConstraint } from '@angular/fire/firestore';

import { buildSessionQueryConstraints } from './firebase-session-read.repository';
import { buildSessionReportQueryConstraints } from './firebase-session-report-read.repository';
import { buildSessionDisputeQueryConstraints } from './firebase-session-dispute-read.repository';
import {
  buildActiveSessionQueryConstraints,
  buildActiveCallQueryConstraints,
} from './firebase-session-read.repository';
import { buildTeacherApplicationQueryConstraints } from './firebase-teacher-application.repository';
import { buildTeacherProfileQueryConstraints } from './firebase-teacher-profile.repository';
import { buildQuranSessionsUserServerFilters } from './firebase-quran-sessions-user.repository';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import { TeacherVerificationStatus } from '../../domain/entities/teacher-profile.entity';
import {
  ACTIVE_SESSION_SERVER_LIFECYCLE_STATUSES,
  resolveActiveSessionWindow,
} from '../../domain/entities/active-session.entity';
import {
  QuranSessionsAccountStatus,
  UserGender,
} from '../../domain/entities/quran-sessions-user.entity';

interface Inspected {
  type: string;
  field?: string;
  op?: string;
  value?: unknown;
}

function inspect(c: QueryConstraint): Inspected {
  const anyC = c as unknown as {
    type: string;
    _field?: { segments: readonly string[] };
    _op?: string;
    _value?: unknown;
  };
  return {
    type: anyC.type,
    field: anyC._field?.segments.join('.'),
    op: anyC._op,
    value: anyC._value,
  };
}

function whereConstraints(cs: readonly QueryConstraint[]): Inspected[] {
  return cs.map(inspect).filter((c) => c.type === 'where');
}

describe('repository query contracts — server-side filters only', () => {
  it('buildSessionQueryConstraints pushes status/geo/participant/range to Firestore', () => {
    const from = new Date(2026, 0, 1);
    const to = new Date(2026, 11, 31);
    const cs = whereConstraints(
      buildSessionQueryConstraints({
        status: SessionLifecycleStatus.Scheduled,
        teacherId: 't1',
        studentId: 's1',
        countryCode: 'EG',
        cityId: 'cairo',
        startsFrom: from,
        startsTo: to,
        search: 'should-not-be-pushed',
      }),
    );

    expect(cs).toContainEqual({
      type: 'where',
      field: 'lifecycleStatus',
      op: '==',
      value: SessionLifecycleStatus.Scheduled,
    });
    expect(cs).toContainEqual({ type: 'where', field: 'teacherId', op: '==', value: 't1' });
    expect(cs).toContainEqual({ type: 'where', field: 'studentId', op: '==', value: 's1' });
    expect(cs).toContainEqual({ type: 'where', field: 'countryCode', op: '==', value: 'EG' });
    expect(cs).toContainEqual({ type: 'where', field: 'cityId', op: '==', value: 'cairo' });
    expect(cs).toContainEqual({ type: 'where', field: 'startsAt', op: '>=', value: from });
    expect(cs).toContainEqual({ type: 'where', field: 'startsAt', op: '<=', value: to });
    expect(cs.find((c) => c.field === 'search')).toBeUndefined();
  });

  it('buildSessionQueryConstraints emits nothing when no filters set', () => {
    expect(
      buildSessionQueryConstraints({
        status: null,
        teacherId: null,
        studentId: null,
        countryCode: null,
        cityId: null,
        startsFrom: null,
        startsTo: null,
        search: null,
      }),
    ).toHaveLength(0);
  });

  it('buildSessionReportQueryConstraints pushes status/severity/category only', () => {
    const cs = whereConstraints(
      buildSessionReportQueryConstraints({
        status: 'open',
        severity: 'high',
        category: 'abuse',
        search: 'xyz',
      }),
    );
    expect(cs).toHaveLength(3);
    expect(cs).toContainEqual({ type: 'where', field: 'status', op: '==', value: 'open' });
    expect(cs).toContainEqual({ type: 'where', field: 'severity', op: '==', value: 'high' });
    expect(cs).toContainEqual({ type: 'where', field: 'category', op: '==', value: 'abuse' });
  });

  it('buildSessionDisputeQueryConstraints pushes status only', () => {
    const cs = whereConstraints(
      buildSessionDisputeQueryConstraints({ status: 'opened', search: 'x' }),
    );
    expect(cs).toEqual([{ type: 'where', field: 'status', op: '==', value: 'opened' }]);
  });

  it('buildTeacherApplicationQueryConstraints pushes geo userId-in, status, range, array-contains', () => {
    const from = new Date(2026, 0, 1);
    const cs = whereConstraints(
      buildTeacherApplicationQueryConstraints(
        {
          status: TeacherApplicationStatus.Pending,
          specialization: 'tajweed',
          submittedFrom: from,
          submittedTo: null,
          search: 'ignore',
          countryCode: null,
          cityId: null,
        },
        ['u1', 'u2'],
      ),
    );
    expect(cs).toContainEqual({ type: 'where', field: 'userId', op: 'in', value: ['u1', 'u2'] });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'status',
      op: '==',
      value: TeacherApplicationStatus.Pending,
    });
    expect(cs).toContainEqual({ type: 'where', field: 'submittedAt', op: '>=', value: from });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'specializations',
      op: 'array-contains',
      value: 'tajweed',
    });
  });

  it('buildTeacherApplicationQueryConstraints omits userId-in when geoUserIds is null', () => {
    const cs = whereConstraints(
      buildTeacherApplicationQueryConstraints(
        {
          search: null,
          status: null,
          specialization: null,
          submittedFrom: null,
          submittedTo: null,
          countryCode: null,
          cityId: null,
        },
        null,
      ),
    );
    expect(cs.find((c) => c.field === 'userId')).toBeUndefined();
  });

  it('buildTeacherProfileQueryConstraints pushes booleans, enum, and array-contains', () => {
    const cs = whereConstraints(
      buildTeacherProfileQueryConstraints({
        isActive: true,
        verificationStatus: TeacherVerificationStatus.Verified,
        language: 'ar',
        specialization: 'tajweed',
        search: 'ignore',
        countryCode: null,
        cityId: null,
      }),
    );
    expect(cs).toContainEqual({ type: 'where', field: 'isActive', op: '==', value: true });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'verificationStatus',
      op: '==',
      value: TeacherVerificationStatus.Verified,
    });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'teachingLanguages',
      op: 'array-contains',
      value: 'ar',
    });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'specializations',
      op: 'array-contains',
      value: 'tajweed',
    });
  });

  it('buildQuranSessionsUserServerFilters pushes nested profile fields, not search', () => {
    const cs = whereConstraints(
      buildQuranSessionsUserServerFilters({
        accountStatus: QuranSessionsAccountStatus.Suspended,
        gender: UserGender.Female,
        countryCode: 'EG',
        cityId: 'cairo',
        profileCompleted: true,
        search: 'ignore',
      }),
    );
    expect(cs).toContainEqual({
      type: 'where',
      field: 'quranSessionsProfile.accountStatus',
      op: '==',
      value: QuranSessionsAccountStatus.Suspended,
    });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'quranSessionsProfile.gender',
      op: '==',
      value: UserGender.Female,
    });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'quranSessionsProfile.countryCode',
      op: '==',
      value: 'EG',
    });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'quranSessionsProfile.cityId',
      op: '==',
      value: 'cairo',
    });
    expect(cs).toContainEqual({
      type: 'where',
      field: 'quranSessionsProfile.profileCompleted',
      op: '==',
      value: true,
    });
    expect(cs.find((c) => c.field?.includes('search'))).toBeUndefined();
  });

  it('buildActiveSessionQueryConstraints uses a bounded time window + operational lifecycle set', () => {
    const now = new Date('2026-06-25T12:00:00Z');
    const window = resolveActiveSessionWindow(now);
    const cs = whereConstraints(buildActiveSessionQueryConstraints(window));

    const statusIn = cs.find((c) => c.field === 'lifecycleStatus');
    expect(statusIn?.op).toBe('in');
    expect(statusIn?.value).toEqual([...ACTIVE_SESSION_SERVER_LIFECYCLE_STATUSES]);

    const from = cs.find((c) => c.field === 'startsAt' && c.op === '>=');
    const to = cs.find((c) => c.field === 'startsAt' && c.op === '<=');
    expect(from?.value).toEqual(window.startsFrom);
    expect(to?.value).toEqual(window.startsTo);
  });

  it('buildActiveCallQueryConstraints queries hasActiveCall == true (no time-window scan)', () => {
    const cs = whereConstraints(buildActiveCallQueryConstraints());

    expect(cs).toEqual([{ type: 'where', field: 'hasActiveCall', op: '==', value: true }]);
    // No startsAt range — catches early joins regardless of scheduled time.
    expect(cs.find((c) => c.field === 'startsAt')).toBeUndefined();
  });
});
