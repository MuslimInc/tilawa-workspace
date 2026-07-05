import { TeacherApplicationStatus } from './teacher-application-status.enum';

/** Private admin-facing application — no Firebase types. */
export interface TeacherApplication {
  readonly id: string;
  readonly userId: string;
  readonly status: TeacherApplicationStatus;
  /** Intended public marketplace name submitted with the application. */
  readonly publicDisplayName: string | null;
  /** Legacy application display-name field. */
  readonly teacherDisplayName: string | null;
  readonly phoneNumber: string | null;
  readonly phoneCountryCode: string | null;
  readonly preferredContactMethod: string | null;
  readonly teachingLanguages: readonly string[];
  readonly specializations: readonly string[];
  readonly bio: string | null;
  readonly submittedAt: Date | null;
  readonly reviewedAt: Date | null;
  readonly reviewedBy: string | null;
  readonly rejectionReason: string | null;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface TeacherApplicationFilters {
  readonly status?: TeacherApplicationStatus | null;
  readonly countryCode?: string | null;
  readonly cityId?: string | null;
  readonly specialization?: string | null;
  readonly submittedFrom?: Date | null;
  readonly submittedTo?: Date | null;
  readonly search?: string | null;
}

export const TEACHER_APPLICATION_DEFAULT_SORT = {
  field: 'updatedAt',
  direction: 'desc',
} as const;

export const TEACHER_APPLICATION_SORT_FIELDS = ['updatedAt', 'submittedAt', 'createdAt'] as const;
