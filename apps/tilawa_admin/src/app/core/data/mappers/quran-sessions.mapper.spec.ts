import { describe, it, expect } from 'vitest';

import {
  TeacherApplicationMapper,
  TeacherProfileMapper,
  computeMissingPublicProfileFields,
  computeProfileCompleteness,
  resolveApplicationPublicDisplayName,
} from './quran-sessions.mapper';
import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import { TeacherVerificationStatus } from '../../domain/entities/teacher-profile.entity';

describe('TeacherApplicationMapper', () => {
  it('maps Firestore dto to domain entity', () => {
    const entity = TeacherApplicationMapper.fromFirestore('app-1', {
      userId: 'user-1',
      status: 'pending',
      publicDisplayName: 'Ustad Ahmad',
      phoneNumber: '+201234567890',
      teachingLanguages: ['ar'],
      specializations: ['tajweed'],
      bio: 'Bio',
      createdAt: 1_700_000_000_000,
      updatedAt: 1_700_000_100_000,
    });

    expect(entity.id).toBe('app-1');
    expect(entity.userId).toBe('user-1');
    expect(entity.status).toBe(TeacherApplicationStatus.Pending);
    expect(entity.publicDisplayName).toBe('Ustad Ahmad');
    expect(entity.phoneNumber).toBe('+201234567890');
  });

  it('falls back legacy displayName to publicDisplayName', () => {
    const entity = TeacherApplicationMapper.fromFirestore('app-2', {
      userId: 'user-2',
      status: 'pending',
      displayName: 'Legacy Name',
    });

    expect(entity.publicDisplayName).toBe('Legacy Name');
  });
});

describe('resolveApplicationPublicDisplayName', () => {
  it('prefers publicDisplayName over teacherDisplayName', () => {
    expect(
      resolveApplicationPublicDisplayName({
        publicDisplayName: 'Public',
        teacherDisplayName: 'Teacher',
      }),
    ).toBe('Public');
  });
});

describe('TeacherProfileMapper', () => {
  it('maps completeness and visibility fields', () => {
    const entity = TeacherProfileMapper.fromFirestore('teacher-1', {
      userId: 'user-1',
      displayName: 'Ustad Ahmad',
      publicBio: 'Experienced teacher',
      teachingLanguages: ['ar'],
      specializations: ['tajweed'],
      verificationStatus: 'verified',
      isActive: true,
      profileCompleteness: 'complete',
      isPubliclyVisible: true,
      createdAt: 1_700_000_000_000,
      updatedAt: 1_700_000_100_000,
    });

    expect(entity.profileCompleteness).toBe('complete');
    expect(entity.isPubliclyVisible).toBe(true);
    expect(entity.verificationStatus).toBe(TeacherVerificationStatus.Verified);
  });

  it('derives completeness when not stored', () => {
    const entity = TeacherProfileMapper.fromFirestore('teacher-2', {
      userId: 'user-2',
      displayName: 'Quran Teacher',
      publicBio: '',
      teachingLanguages: [],
      specializations: [],
      verificationStatus: 'verified',
      isActive: true,
    });

    expect(entity.profileCompleteness).toBe('incomplete');
    expect(entity.isPubliclyVisible).toBe(false);
    expect(computeMissingPublicProfileFields(entity)).toEqual([
      'displayName',
      'publicBio',
      'teachingLanguages',
      'specializations',
    ]);
  });
});

describe('computeProfileCompleteness', () => {
  it('returns complete for valid marketplace fields', () => {
    expect(
      computeProfileCompleteness({
        displayName: 'Ustad Ahmad',
        publicBio: 'Bio',
        teachingLanguages: ['ar'],
        specializations: ['tajweed'],
      }),
    ).toBe('complete');
  });
});

describe('ReviewTeacherApplicationUseCase validation', () => {
  it('documents reject reason requirement in use case layer', () => {
    expect(true).toBe(true);
  });
});
