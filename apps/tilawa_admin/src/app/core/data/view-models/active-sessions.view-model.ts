import { AdminSessionSummary } from '../../domain/entities/admin-session-summary.entity';
import { ActiveSessionOperationalStatus } from '../../domain/entities/active-session.entity';
import { TeacherProfile } from '../../domain/entities/teacher-profile.entity';
import { QuranSessionsUser } from '../../domain/entities/quran-sessions-user.entity';
import { CallTrackingSummary } from '../../domain/entities/call-tracking.entity';
import { enrichActiveSessionRow } from '../mappers/active-session.mapper';
import {
  SessionParticipantJoinStatus,
  SessionCallPhase,
} from './quran-sessions.view-model';

export interface ActiveSessionListItemVm {
  readonly bookingId: string;
  readonly sessionId: string | null;
  readonly startsAt: Date;
  readonly endsAt: Date | null;
  readonly lifecycleStatus: string;
  readonly callType: string;
  readonly operationalStatus: ActiveSessionOperationalStatus;
  readonly callPhase: SessionCallPhase;
  readonly teacherId: string;
  readonly teacherName: string | null;
  readonly teacherAccountStatus: string | null;
  readonly teacherIsActive: boolean | null;
  readonly teacherUserId: string | null;
  readonly studentId: string;
  readonly studentName: string | null;
  readonly studentAccountStatus: string | null;
  readonly whoJoinedFirst: string;
  readonly teacherJoinStatus: SessionParticipantJoinStatus;
  readonly studentJoinStatus: SessionParticipantJoinStatus;
  readonly teacherLate: boolean;
  readonly studentLate: boolean;
  readonly teacherNoShow: boolean;
  readonly studentNoShow: boolean;
  readonly connectedMinutes: number;
  readonly reconnectCount: number;
  readonly interruptionCount: number;
  readonly providerType: string;
  readonly trackingUpdatedAt: Date | null;
}

export class ActiveSessionsViewModelMapper {
  static toListItem(input: {
    session: AdminSessionSummary;
    summary: CallTrackingSummary | null;
    teacher: TeacherProfile | null;
    teacherUser: QuranSessionsUser | null;
    student: QuranSessionsUser | null;
    now?: Date;
  }): ActiveSessionListItemVm {
    const enrichment = enrichActiveSessionRow(
      input.session,
      input.summary,
      input.now,
    );

    return {
      bookingId: input.session.id,
      sessionId: input.session.sessionId,
      startsAt: input.session.startsAt,
      endsAt: input.session.endsAt,
      lifecycleStatus: input.session.lifecycleStatus,
      callType: input.session.callType,
      operationalStatus: enrichment.operationalStatus,
      callPhase: enrichment.callPhase,
      teacherId: input.session.teacherId,
      teacherName: input.teacher?.displayName ?? null,
      teacherAccountStatus: input.teacherUser?.accountStatus ?? null,
      teacherIsActive: input.teacher?.isActive ?? null,
      teacherUserId: input.teacher?.userId ?? null,
      studentId: input.session.studentId,
      studentName:
        input.student?.displayName ?? input.student?.email ?? null,
      studentAccountStatus: input.student?.accountStatus ?? null,
      whoJoinedFirst: enrichment.whoJoinedFirst,
      teacherJoinStatus: enrichment.teacherJoinStatus,
      studentJoinStatus: enrichment.studentJoinStatus,
      teacherLate: enrichment.teacherLate,
      studentLate: enrichment.studentLate,
      teacherNoShow: enrichment.teacherNoShow,
      studentNoShow: enrichment.studentNoShow,
      connectedMinutes: enrichment.connectedMinutes,
      reconnectCount: enrichment.reconnectCount,
      interruptionCount: enrichment.interruptionCount,
      providerType: input.session.callType,
      trackingUpdatedAt: enrichment.trackingUpdatedAt,
    };
  }
}
