import { TeacherApplication } from '../../domain/entities/teacher-application.entity';
import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import {
  ProfileCompleteness,
  TeacherProfile,
} from '../../domain/entities/teacher-profile.entity';
import { QuranSessionsUser } from '../../domain/entities/quran-sessions-user.entity';
import {
  computeMissingPublicProfileFields,
  resolveApplicationPublicDisplayName,
} from '../mappers/quran-sessions.mapper';

export interface TeacherApplicationListItemVm {
  readonly id: string;
  readonly userId: string;
  readonly publicDisplayName: string;
  readonly accountDisplayName: string;
  readonly email: string;
  readonly phoneNumber: string | null;
  readonly status: string;
  readonly submittedAt: Date | null;
  readonly canReview: boolean;
}

export interface TeacherApplicationDetailVm {
  readonly id: string;
  readonly userId: string;
  readonly publicDisplayName: string;
  readonly accountDisplayName: string;
  readonly avatarUrl: string | null;
  readonly email: string;
  readonly phoneNumber: string | null;
  readonly gender: string | null;
  readonly dateOfBirth: Date | null;
  readonly country: string;
  readonly city: string;
  readonly contactMethod: string | null;
  readonly languages: readonly string[];
  readonly specializations: readonly string[];
  readonly bio: string | null;
  readonly submittedAt: Date | null;
  readonly reviewedAt: Date | null;
  readonly reviewedBy: string | null;
  readonly rejectionReason: string | null;
  readonly status: string;
}

export interface TeacherListItemVm {
  readonly id: string;
  readonly displayName: string;
  readonly userId: string;
  readonly isActive: boolean;
  readonly verificationStatus: string;
  readonly profileCompleteness: ProfileCompleteness;
  readonly isPubliclyVisible: boolean;
  readonly missingFields: readonly string[];
}

export interface QuranSessionsUserListItemVm {
  readonly userId: string;
  readonly displayName: string;
  readonly email: string;
  readonly photoUrl: string | null;
  readonly accountStatus: string;
  readonly hasDuplicateEmail: boolean;
}

export class QuranSessionsViewModelMapper {
  static toApplicationListItem(
    application: TeacherApplication,
    user: QuranSessionsUser | null,
  ): TeacherApplicationListItemVm {
    return {
      id: application.id,
      userId: application.userId,
      publicDisplayName:
        resolveApplicationPublicDisplayName(application) ?? '—',
      accountDisplayName: user?.displayName ?? '—',
      email: user?.email ?? '—',
      phoneNumber: application.phoneNumber,
      status: application.status,
      submittedAt: application.submittedAt,
      canReview: application.status === TeacherApplicationStatus.Pending,
    };
  }

  static toApplicationDetail(
    application: TeacherApplication,
    user: QuranSessionsUser | null,
  ): TeacherApplicationDetailVm {
    return {
      id: application.id,
      userId: application.userId,
      publicDisplayName:
        resolveApplicationPublicDisplayName(application) ?? '—',
      accountDisplayName: user?.displayName ?? '—',
      avatarUrl: user?.avatarUrl ?? null,
      email: user?.email ?? '—',
      phoneNumber: application.phoneNumber,
      gender: user?.gender ?? null,
      dateOfBirth: null,
      country: user?.countryName ?? user?.countryCode ?? '—',
      city: user?.cityName ?? user?.cityId ?? '—',
      contactMethod: application.preferredContactMethod,
      languages: application.teachingLanguages,
      specializations: application.specializations,
      bio: application.bio,
      submittedAt: application.submittedAt,
      reviewedAt: application.reviewedAt,
      reviewedBy: application.reviewedBy,
      rejectionReason: application.rejectionReason,
      status: application.status,
    };
  }

  static toTeacherListItem(profile: TeacherProfile): TeacherListItemVm {
    return {
      id: profile.id,
      displayName: profile.displayName || '—',
      userId: profile.userId,
      isActive: profile.isActive,
      verificationStatus: profile.verificationStatus,
      profileCompleteness: profile.profileCompleteness,
      isPubliclyVisible: profile.isPubliclyVisible,
      missingFields: computeMissingPublicProfileFields(profile),
    };
  }

  static toUserListItem(
    user: QuranSessionsUser,
    hasDuplicateEmail: boolean,
  ): QuranSessionsUserListItemVm {
    return {
      userId: user.userId,
      displayName: user.displayName ?? '—',
      email: user.email ?? '—',
      photoUrl: user.avatarUrl,
      accountStatus: user.accountStatus,
      hasDuplicateEmail,
    };
  }
}
