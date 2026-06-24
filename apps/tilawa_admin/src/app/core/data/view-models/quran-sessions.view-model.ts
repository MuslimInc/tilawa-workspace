import { TeacherApplication } from '../../domain/entities/teacher-application.entity';
import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import {
  ProfileCompleteness,
  TeacherProfile,
} from '../../domain/entities/teacher-profile.entity';
import { QuranSessionsUser } from '../../domain/entities/quran-sessions-user.entity';
import { AdminSessionSummary } from '../../domain/entities/admin-session-summary.entity';
import { SessionCompensationSummary } from '../../domain/entities/session-compensation-summary.entity';
import { SessionTimelineEvent } from '../../domain/entities/session-timeline-event.entity';
import {
  CallEvent,
  CallTrackingSummary,
} from '../../domain/entities/call-tracking.entity';
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
  readonly updatedAt: Date;
  readonly createdAt: Date;
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
  readonly updatedAt: Date;
  readonly createdAt: Date;
}

export interface QuranSessionsUserListItemVm {
  readonly userId: string;
  readonly displayName: string;
  readonly email: string;
  readonly photoUrl: string | null;
  readonly accountStatus: string;
  readonly hasDuplicateEmail: boolean;
  readonly updatedAt: Date | null;
  readonly createdAt: Date | null;
}

export interface AdminSessionListItemVm {
  readonly id: string;
  readonly sessionId: string | null;
  readonly studentId: string;
  readonly teacherId: string;
  readonly startsAt: Date;
  readonly lifecycleStatus: string;
  readonly callType: string;
  readonly pricingType: string;
  readonly countryCode: string;
  readonly cityId: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface AdminSessionDetailVm {
  readonly id: string;
  readonly aggregateId: string;
  readonly sessionId: string | null;
  readonly studentId: string;
  readonly teacherId: string;
  readonly slotId: string;
  readonly startsAt: Date;
  readonly endsAt: Date | null;
  readonly lifecycleStatus: string;
  readonly callType: string;
  readonly pricingType: string;
  readonly countryCode: string;
  readonly cityId: string;
  readonly paymentStatus: string;
  readonly amountPaidUsd: string;
  readonly cancellationReason: string | null;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface SessionTimelineEventVm {
  readonly id: string;
  readonly action: string;
  readonly actorRole: string;
  readonly actorId: string;
  readonly previousStatus: string;
  readonly newStatus: string;
  readonly reason: string;
  readonly source: string;
  readonly timestamp: Date;
}

export interface SessionCompensationVm {
  readonly id: string;
  readonly type: string;
  readonly status: string;
  readonly amountUsd: string;
  readonly issuedByRole: string;
  readonly createdAt: Date;
  readonly completedAt: Date | null;
}

export interface CallTrackingVm {
  readonly whoJoinedFirst: string;
  readonly teacherJoinedAt: Date | null;
  readonly studentJoinedAt: Date | null;
  readonly teacherLate: boolean | null;
  readonly studentLate: boolean | null;
  readonly teacherDelayMinutes: number | null;
  readonly studentDelayMinutes: number | null;
  readonly actualCallStartedAt: Date | null;
  readonly actualCallEndedAt: Date | null;
  readonly connectedSeconds: number;
  readonly connectedMinutes: number;
  readonly reconnectCount: number;
  readonly interruptionCount: number;
  readonly teacherNoShow: boolean;
  readonly studentNoShow: boolean;
  readonly providerType: string;
  readonly updatedAt: Date | null;
}

export interface CallEventVm {
  readonly id: string;
  readonly eventType: string;
  readonly actorRole: string;
  readonly detail: string;
  readonly recordedAt: Date | null;
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
      updatedAt: application.updatedAt,
      createdAt: application.createdAt,
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
      updatedAt: profile.updatedAt,
      createdAt: profile.createdAt,
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
      updatedAt: user.updatedAt,
      createdAt: user.createdAt,
    };
  }

  static toSessionListItem(session: AdminSessionSummary): AdminSessionListItemVm {
    return {
      id: session.id,
      sessionId: session.sessionId,
      studentId: session.studentId,
      teacherId: session.teacherId,
      startsAt: session.startsAt,
      lifecycleStatus: session.lifecycleStatus,
      callType: session.callType,
      pricingType: session.pricingType,
      countryCode: session.countryCode ?? '—',
      cityId: session.cityId ?? '—',
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    };
  }

  static toSessionDetail(session: AdminSessionSummary): AdminSessionDetailVm {
    return {
      id: session.id,
      aggregateId: session.aggregateId,
      sessionId: session.sessionId,
      studentId: session.studentId,
      teacherId: session.teacherId,
      slotId: session.slotId,
      startsAt: session.startsAt,
      endsAt: session.endsAt,
      lifecycleStatus: session.lifecycleStatus,
      callType: session.callType,
      pricingType: session.pricingType,
      countryCode: session.countryCode ?? '—',
      cityId: session.cityId ?? '—',
      paymentStatus: session.paymentStatus ?? '—',
      amountPaidUsd:
        session.amountPaidUsd == null ? '—' : session.amountPaidUsd.toFixed(2),
      cancellationReason: session.cancellationReason,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    };
  }

  static toTimelineEvent(event: SessionTimelineEvent): SessionTimelineEventVm {
    return {
      id: event.id,
      action: event.action,
      actorRole: event.actorRole,
      actorId: event.actorId,
      previousStatus: event.previousStatus ?? '—',
      newStatus: event.newStatus,
      reason: event.reason ?? '—',
      source: event.source,
      timestamp: event.timestamp,
    };
  }

  static toCompensation(
    compensation: SessionCompensationSummary,
  ): SessionCompensationVm {
    return {
      id: compensation.id,
      type: compensation.type,
      status: compensation.status,
      amountUsd:
        compensation.amountUsd == null
          ? '—'
          : compensation.amountUsd.toFixed(2),
      issuedByRole: compensation.issuedByRole,
      createdAt: compensation.createdAt,
      completedAt: compensation.completedAt,
    };
  }

  static toCallTracking(
    summary: CallTrackingSummary,
    providerType: string,
  ): CallTrackingVm {
    const teacherJoinedAt = resolveJoinAt(summary, 'teacher');
    const studentJoinedAt = resolveJoinAt(summary, 'student');
    const connectedSeconds = Math.max(
      0,
      summary.bothParticipantsConnectedSeconds,
    );
    return {
      whoJoinedFirst: summary.firstJoinRole ?? '—',
      teacherJoinedAt,
      studentJoinedAt,
      teacherLate: summary.teacherLate,
      studentLate: summary.studentLate,
      teacherDelayMinutes: computeDelayMinutes(
        summary.scheduledStartsAt,
        teacherJoinedAt,
      ),
      studentDelayMinutes: computeDelayMinutes(
        summary.scheduledStartsAt,
        studentJoinedAt,
      ),
      actualCallStartedAt: summary.actualCallStartedAt,
      actualCallEndedAt: summary.callEndedAt,
      connectedSeconds,
      connectedMinutes: Math.floor(connectedSeconds / 60),
      reconnectCount: summary.reconnectCount,
      interruptionCount: summary.interruptionCount,
      teacherNoShow: summary.teacherNoShow,
      studentNoShow: summary.studentNoShow,
      providerType,
      updatedAt: summary.updatedAt,
    };
  }

  static toCallEvent(event: CallEvent): CallEventVm {
    const parts = [event.reasonCode, event.networkQuality].filter(
      (part): part is string => !!part,
    );
    return {
      id: event.id,
      eventType: event.eventType,
      actorRole: event.actorRole,
      detail: parts.length > 0 ? parts.join(' · ') : '—',
      recordedAt: event.recordedAt,
    };
  }
}

/** Resolves a participant's first-connect time from the role-tagged joins. */
function resolveJoinAt(
  summary: CallTrackingSummary,
  role: 'teacher' | 'student',
): Date | null {
  if (summary.firstJoinRole === role) {
    return summary.firstJoinAt;
  }
  if (summary.secondJoinRole === role) {
    return summary.secondJoinAt;
  }
  return null;
}

/** Whole minutes between the scheduled start and a join, clamped at zero. */
function computeDelayMinutes(
  scheduledStartsAt: Date | null,
  joinedAt: Date | null,
): number | null {
  if (!scheduledStartsAt || !joinedAt) {
    return null;
  }
  const deltaMs = joinedAt.getTime() - scheduledStartsAt.getTime();
  if (deltaMs <= 0) {
    return 0;
  }
  return Math.floor(deltaMs / 60_000);
}
