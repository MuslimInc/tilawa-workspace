export enum TeacherVerificationStatus {
  Pending = 'pending',
  Verified = 'verified',
  Rejected = 'rejected',
}

export type ProfileCompleteness = 'complete' | 'incomplete';

/** Public teacher projection — never includes phone or moderation notes. */
export interface TeacherProfile {
  readonly id: string;
  readonly userId: string;
  readonly displayName: string;
  readonly avatarUrl: string | null;
  readonly publicBio: string | null;
  readonly verificationStatus: TeacherVerificationStatus;
  readonly teachingLanguages: readonly string[];
  readonly specializations: readonly string[];
  readonly averageRating: number;
  readonly reviewCount: number;
  readonly isActive: boolean;
  readonly profileCompleteness: ProfileCompleteness;
  readonly isPubliclyVisible: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface TeacherProfileFilters {
  readonly countryCode?: string | null;
  readonly cityId?: string | null;
  readonly isActive?: boolean | null;
  readonly verificationStatus?: TeacherVerificationStatus | null;
  readonly language?: string | null;
  readonly specialization?: string | null;
  readonly search?: string | null;
}

export const TEACHER_PROFILE_DEFAULT_SORT = {
  field: 'updatedAt',
  direction: 'desc',
} as const;

export const TEACHER_PROFILE_SORT_FIELDS = [
  'updatedAt',
  'createdAt',
  'displayName',
] as const;
