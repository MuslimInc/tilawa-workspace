import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import { TeacherApplication } from '../../domain/entities/teacher-application.entity';
import {
  ProfileCompleteness,
  TeacherProfile,
  TeacherVerificationStatus,
} from '../../domain/entities/teacher-profile.entity';
import { QuranSessionsUser, UserGender } from '../../domain/entities/quran-sessions-user.entity';

const TEACHER_DISPLAY_NAME_PLACEHOLDERS = ['Quran Teacher', 'محفظ قرآن'] as const;

function trimString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function isPlaceholderDisplayName(name: string): boolean {
  return TEACHER_DISPLAY_NAME_PLACEHOLDERS.includes(
    name as (typeof TEACHER_DISPLAY_NAME_PLACEHOLDERS)[number],
  );
}

export function isValidTeacherDisplayName(name: string): boolean {
  const trimmed = name.trim();
  return trimmed.length > 0 && !isPlaceholderDisplayName(trimmed);
}

export function computeProfileCompleteness(profile: {
  displayName: string;
  publicBio: string | null;
  teachingLanguages: readonly string[];
  specializations: readonly string[];
}): ProfileCompleteness {
  if (!isValidTeacherDisplayName(profile.displayName)) {
    return 'incomplete';
  }
  if (!trimString(profile.publicBio)) {
    return 'incomplete';
  }
  if (profile.teachingLanguages.length === 0) {
    return 'incomplete';
  }
  if (profile.specializations.length === 0) {
    return 'incomplete';
  }
  return 'complete';
}

export function computeIsPubliclyVisible(profile: {
  profileCompleteness: ProfileCompleteness;
  verificationStatus: TeacherVerificationStatus;
  isActive: boolean;
}): boolean {
  return (
    profile.profileCompleteness === 'complete' &&
    profile.verificationStatus === TeacherVerificationStatus.Verified &&
    profile.isActive
  );
}

export function computeMissingPublicProfileFields(profile: {
  displayName: string;
  publicBio: string | null;
  teachingLanguages: readonly string[];
  specializations: readonly string[];
}): readonly string[] {
  const missing: string[] = [];
  if (!isValidTeacherDisplayName(profile.displayName)) {
    missing.push('displayName');
  }
  if (!trimString(profile.publicBio)) {
    missing.push('publicBio');
  }
  if (profile.teachingLanguages.length === 0) {
    missing.push('teachingLanguages');
  }
  if (profile.specializations.length === 0) {
    missing.push('specializations');
  }
  return missing;
}

export function resolveApplicationPublicDisplayName(
  application: Pick<
    TeacherApplication,
    'publicDisplayName' | 'teacherDisplayName'
  >,
): string | null {
  for (const candidate of [
    application.publicDisplayName,
    application.teacherDisplayName,
  ]) {
    const trimmed = trimString(candidate);
    if (trimmed.length > 0) {
      return trimmed;
    }
  }
  return null;
}

/** Firestore document shape — infrastructure only. */
export interface TeacherApplicationFirestoreDto {
  userId: string;
  status: string;
  publicDisplayName?: string;
  teacherDisplayName?: string;
  displayName?: string;
  phoneNumber?: string;
  phoneCountryCode?: string;
  preferredContactMethod?: string;
  teachingLanguages?: string[];
  specializations?: string[];
  bio?: string;
  submittedAt?: unknown;
  reviewedAt?: unknown;
  reviewedBy?: string;
  rejectionReason?: string;
  createdAt?: unknown;
  updatedAt?: unknown;
}

export interface TeacherProfileFirestoreDto {
  userId: string;
  displayName?: string;
  avatarUrl?: string;
  publicBio?: string;
  verificationStatus?: string;
  teachingLanguages?: string[];
  specializations?: string[];
  averageRating?: number;
  reviewCount?: number;
  isActive?: boolean;
  profileCompleteness?: string;
  isPubliclyVisible?: boolean;
  createdAt?: unknown;
  updatedAt?: unknown;
}

export interface TilawaUserFirestoreDto {
  email?: string;
  displayName?: string;
  photoUrl?: string;
  quranSessionsProfile?: Record<string, unknown>;
  deletion?: {
    purgeAfter?: unknown;
  };
}

export function readTimestamp(value: unknown): Date | null {
  if (value == null) {
    return null;
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    const maybeDate = (value as { toDate: () => Date }).toDate();
    return maybeDate instanceof Date ? maybeDate : null;
  }
  if (typeof value === 'number') {
    return new Date(value);
  }
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : new Date(parsed);
  }
  return null;
}

export function readRequiredTimestamp(value: unknown, fallback: Date): Date {
  return readTimestamp(value) ?? fallback;
}

export function parseApplicationStatus(raw: string): TeacherApplicationStatus {
  const values = Object.values(TeacherApplicationStatus);
  return values.includes(raw as TeacherApplicationStatus)
    ? (raw as TeacherApplicationStatus)
    : TeacherApplicationStatus.None;
}

export class TeacherApplicationMapper {
  static fromFirestore(
    id: string,
    dto: TeacherApplicationFirestoreDto,
  ): TeacherApplication {
    const now = new Date();
    return {
      id,
      userId: dto.userId ?? '',
      status: parseApplicationStatus(dto.status ?? 'none'),
      publicDisplayName:
        trimString(dto.publicDisplayName) ||
        trimString(dto.displayName) ||
        null,
      teacherDisplayName: trimString(dto.teacherDisplayName) || null,
      phoneNumber: dto.phoneNumber ?? null,
      phoneCountryCode: dto.phoneCountryCode ?? null,
      preferredContactMethod: dto.preferredContactMethod ?? null,
      teachingLanguages: dto.teachingLanguages ?? [],
      specializations: dto.specializations ?? [],
      bio: dto.bio ?? null,
      submittedAt: readTimestamp(dto.submittedAt),
      reviewedAt: readTimestamp(dto.reviewedAt),
      reviewedBy: dto.reviewedBy ?? null,
      rejectionReason: dto.rejectionReason ?? null,
      createdAt: readRequiredTimestamp(dto.createdAt, now),
      updatedAt: readRequiredTimestamp(dto.updatedAt, now),
    };
  }
}

export class TeacherProfileMapper {
  static fromFirestore(
    id: string,
    dto: TeacherProfileFirestoreDto,
  ): TeacherProfile {
    const now = new Date();
    const rawStatus = dto.verificationStatus ?? 'pending';
    const verificationStatus = rawStatus as TeacherVerificationStatus;
    const displayName = dto.displayName ?? '';
    const publicBio = dto.publicBio ?? null;
    const teachingLanguages = dto.teachingLanguages ?? [];
    const specializations = dto.specializations ?? [];
    const isActive = dto.isActive ?? false;

    const profileCompleteness =
      dto.profileCompleteness === 'complete' || dto.profileCompleteness === 'incomplete'
        ? dto.profileCompleteness
        : computeProfileCompleteness({
            displayName,
            publicBio,
            teachingLanguages,
            specializations,
          });

    const isPubliclyVisible =
      typeof dto.isPubliclyVisible === 'boolean'
        ? dto.isPubliclyVisible
        : computeIsPubliclyVisible({
            profileCompleteness,
            verificationStatus,
            isActive,
          });

    return {
      id,
      userId: dto.userId ?? '',
      displayName,
      avatarUrl: dto.avatarUrl ?? null,
      publicBio,
      verificationStatus,
      teachingLanguages,
      specializations,
      averageRating: dto.averageRating ?? 0,
      reviewCount: dto.reviewCount ?? 0,
      isActive,
      profileCompleteness,
      isPubliclyVisible,
      createdAt: readRequiredTimestamp(dto.createdAt, now),
      updatedAt: readRequiredTimestamp(dto.updatedAt, now),
    };
  }
}

export class QuranSessionsUserMapper {
  static fromUserDoc(
    userId: string,
    dto: TilawaUserFirestoreDto,
  ): QuranSessionsUser | null {
    const profile = dto.quranSessionsProfile;
    if (!profile) {
      return null;
    }

    const genderRaw = profile['gender'] as string | undefined;
    const statusRaw = (profile['accountStatus'] as string | undefined) ?? 'active';
    const deletionPurgeAfter = readTimestamp(dto.deletion?.purgeAfter);

    return {
      userId,
      email: dto.email ?? null,
      displayName: dto.displayName ?? null,
      avatarUrl: dto.photoUrl ?? null,
      gender:
        genderRaw === UserGender.Male || genderRaw === UserGender.Female
          ? genderRaw
          : null,
      countryCode: (profile['countryCode'] as string | undefined) ?? null,
      countryName: (profile['countryName'] as string | undefined) ?? null,
      cityId: (profile['cityId'] as string | undefined) ?? null,
      cityName: (profile['cityName'] as string | undefined) ?? null,
      profileCompleted: (profile['profileCompleted'] as boolean | undefined) ?? false,
      accountStatus: statusRaw as QuranSessionsUser['accountStatus'],
      canApplyAsTeacher:
        typeof profile['canApplyAsTeacher'] === 'boolean'
          ? (profile['canApplyAsTeacher'] as boolean)
          : null,
      deletionPurgeAfter,
      createdAt: readTimestamp(profile['createdAt']),
      updatedAt: readTimestamp(profile['updatedAt']),
    };
  }
}
