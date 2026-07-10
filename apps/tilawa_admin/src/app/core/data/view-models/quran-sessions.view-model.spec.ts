import { describe, it, expect } from 'vitest';

import {
  QuranSessionsViewModelMapper,
  resolveParticipantJoinStatus,
  resolveSessionCallPhase,
} from './quran-sessions.view-model';
import { TeacherVerificationStatus } from '../../domain/entities/teacher-profile.entity';
import { QuranSessionsAccountStatus } from '../../domain/entities/quran-sessions-user.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';

function callTracking(
  overrides: Partial<{
    teacherJoinedAt: Date | null;
    studentJoinedAt: Date | null;
    actualCallStartedAt: Date | null;
    actualCallEndedAt: Date | null;
    teacherNoShow: boolean;
    studentNoShow: boolean;
  }> = {},
) {
  return {
    whoJoinedFirst: 'teacher',
    teacherJoinedAt: overrides.teacherJoinedAt ?? null,
    studentJoinedAt: overrides.studentJoinedAt ?? null,
    teacherLate: false,
    studentLate: false,
    teacherDelayMinutes: null,
    studentDelayMinutes: null,
    actualCallStartedAt: overrides.actualCallStartedAt ?? null,
    actualCallEndedAt: overrides.actualCallEndedAt ?? null,
    connectedSeconds: 0,
    connectedMinutes: 0,
    reconnectCount: 0,
    interruptionCount: 0,
    teacherNoShow: overrides.teacherNoShow ?? false,
    studentNoShow: overrides.studentNoShow ?? false,
    providerType: 'agora',
    updatedAt: null,
  };
}

describe('resolveSessionCallPhase', () => {
  it('returns not_started when no call tracking exists', () => {
    expect(resolveSessionCallPhase(SessionLifecycleStatus.Scheduled, null)).toBe('not_started');
  });

  it('returns waiting when one participant joined', () => {
    expect(
      resolveSessionCallPhase(
        SessionLifecycleStatus.InProgress,
        callTracking({ teacherJoinedAt: new Date() }),
      ),
    ).toBe('waiting');
  });

  it('returns active when call started', () => {
    expect(
      resolveSessionCallPhase(
        SessionLifecycleStatus.InProgress,
        callTracking({ actualCallStartedAt: new Date() }),
      ),
    ).toBe('active');
  });

  it('returns ended when call ended', () => {
    expect(
      resolveSessionCallPhase(
        SessionLifecycleStatus.InProgress,
        callTracking({ actualCallEndedAt: new Date() }),
      ),
    ).toBe('ended');
  });
});

describe('resolveParticipantJoinStatus', () => {
  it('returns not_available without call tracking', () => {
    expect(resolveParticipantJoinStatus(null, 'teacher')).toBe('not_available');
  });

  it('surfaces teacher no-show', () => {
    expect(resolveParticipantJoinStatus(callTracking({ teacherNoShow: true }), 'teacher')).toBe(
      'no_show',
    );
  });

  it('surfaces student blocked path via joined state', () => {
    expect(
      resolveParticipantJoinStatus(callTracking({ studentJoinedAt: new Date() }), 'student'),
    ).toBe('joined');
  });
});

describe('QuranSessionsViewModelMapper.toSessionParticipants', () => {
  it('maps loaded teacher and student with session association', () => {
    const vm = QuranSessionsViewModelMapper.toSessionParticipants({
      session: {
        teacherId: 'teacher-1',
        studentId: 'student-1',
        lifecycleStatus: SessionLifecycleStatus.Scheduled,
      },
      teacherProfile: {
        id: 'teacher-1',
        userId: 'user-teacher',
        displayName: 'Ustad Ahmad',
        avatarUrl: null,
        publicBio: 'Bio',
        verificationStatus: TeacherVerificationStatus.Verified,
        teachingLanguages: ['ar'],
        specializations: ['tajweed'],
        averageRating: 5,
        reviewCount: 1,
        isActive: true,
        profileCompleteness: 'complete',
        isPubliclyVisible: true,
        sessionPriceOverride: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      teacherUser: {
        userId: 'user-teacher',
        email: 'teacher@example.com',
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
        deletionPurgeAfter: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      studentUser: {
        userId: 'student-1',
        email: 'student@example.com',
        displayName: 'Fatima',
        avatarUrl: null,
        gender: null,
        countryCode: 'EG',
        countryName: 'Egypt',
        cityId: 'cairo',
        cityName: 'Cairo',
        profileCompleted: true,
        accountStatus: QuranSessionsAccountStatus.Blocked,
        canApplyAsTeacher: true,
        deletionPurgeAfter: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      callTracking: callTracking({
        teacherJoinedAt: new Date('2026-06-24T12:01:00Z'),
      }),
    });

    expect(vm.teacher.loadState).toBe('loaded');
    expect(vm.teacher.displayName).toBe('Ustad Ahmad');
    expect(vm.teacher.accountStatus).toBe('active');
    expect(vm.teacher.matchesSession).toBe(true);
    expect(vm.teacher.sessionJoinStatus).toBe('joined');

    expect(vm.student.loadState).toBe('loaded');
    expect(vm.student.accountStatus).toBe('blocked');
    expect(vm.student.matchesSession).toBe(true);
  });

  it('shows not_found warnings when profiles are missing', () => {
    const vm = QuranSessionsViewModelMapper.toSessionParticipants({
      session: {
        teacherId: 'missing-teacher',
        studentId: 'missing-student',
        lifecycleStatus: SessionLifecycleStatus.Scheduled,
      },
      teacherProfile: null,
      teacherUser: null,
      studentUser: null,
      callTracking: null,
    });

    expect(vm.teacher.loadState).toBe('not_found');
    expect(vm.student.loadState).toBe('not_found');
    expect(vm.teacher.matchesSession).toBe(false);
    expect(vm.student.matchesSession).toBe(false);
  });

  it('shows suspended teacher account status when available', () => {
    const vm = QuranSessionsViewModelMapper.toSessionParticipants({
      session: {
        teacherId: 'teacher-1',
        studentId: 'student-1',
        lifecycleStatus: SessionLifecycleStatus.Scheduled,
      },
      teacherProfile: {
        id: 'teacher-1',
        userId: 'user-teacher',
        displayName: 'Suspended Teacher',
        avatarUrl: null,
        publicBio: null,
        verificationStatus: TeacherVerificationStatus.Verified,
        teachingLanguages: [],
        specializations: [],
        averageRating: 0,
        reviewCount: 0,
        isActive: false,
        profileCompleteness: 'complete',
        isPubliclyVisible: false,
        sessionPriceOverride: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      teacherUser: {
        userId: 'user-teacher',
        email: 't@example.com',
        displayName: 'Suspended Teacher',
        avatarUrl: null,
        gender: null,
        countryCode: null,
        countryName: null,
        cityId: null,
        cityName: null,
        profileCompleted: true,
        accountStatus: QuranSessionsAccountStatus.Suspended,
        canApplyAsTeacher: false,
        deletionPurgeAfter: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      studentUser: null,
      callTracking: null,
    });

    expect(vm.teacher.isActive).toBe(false);
    expect(vm.teacher.accountStatus).toBe('suspended');
  });
});
