import { AdminSessionSummary } from '../../domain/entities/admin-session-summary.entity';
import {
  ACTIVE_SESSION_RECENTLY_ENDED_MS,
  ActiveSessionOperationalStatus,
} from '../../domain/entities/active-session.entity';
import { CallTrackingSummary } from '../../domain/entities/call-tracking.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import {
  resolveParticipantJoinStatus,
  resolveSessionCallPhase,
} from '../view-models/quran-sessions.view-model';

export interface ActiveSessionEnrichment {
  readonly operationalStatus: ActiveSessionOperationalStatus;
  readonly callPhase: ReturnType<typeof resolveSessionCallPhase>;
  readonly teacherJoinStatus: ReturnType<typeof resolveParticipantJoinStatus>;
  readonly studentJoinStatus: ReturnType<typeof resolveParticipantJoinStatus>;
  readonly whoJoinedFirst: string;
  readonly teacherLate: boolean;
  readonly studentLate: boolean;
  readonly teacherNoShow: boolean;
  readonly studentNoShow: boolean;
  readonly connectedMinutes: number;
  readonly reconnectCount: number;
  readonly interruptionCount: number;
  readonly trackingUpdatedAt: Date | null;
}

function callTrackingVm(summary: CallTrackingSummary | null, callType: string) {
  if (!summary) {
    return null;
  }
  const teacherJoinedAt = resolveJoinAt(summary, 'teacher');
  const studentJoinedAt = resolveJoinAt(summary, 'student');
  const connectedSeconds = Math.max(0, summary.bothParticipantsConnectedSeconds);
  return {
    whoJoinedFirst: summary.firstJoinRole ?? '—',
    teacherJoinedAt,
    studentJoinedAt,
    teacherLate: summary.teacherLate,
    studentLate: summary.studentLate,
    teacherDelayMinutes: null,
    studentDelayMinutes: null,
    actualCallStartedAt: summary.actualCallStartedAt,
    actualCallEndedAt: summary.callEndedAt,
    connectedSeconds,
    connectedMinutes: Math.floor(connectedSeconds / 60),
    reconnectCount: summary.reconnectCount,
    interruptionCount: summary.interruptionCount,
    teacherNoShow: summary.teacherNoShow,
    studentNoShow: summary.studentNoShow,
    providerType: callType,
    updatedAt: summary.updatedAt,
  };
}

function resolveJoinAt(summary: CallTrackingSummary, role: 'teacher' | 'student'): Date | null {
  if (summary.firstJoinRole === role) {
    return summary.firstJoinAt;
  }
  if (summary.secondJoinRole === role) {
    return summary.secondJoinAt;
  }
  return null;
}

function roleJoined(summary: CallTrackingSummary, role: 'teacher' | 'student'): boolean {
  return (
    summary.firstJoinRole === role ||
    summary.secondJoinRole === role ||
    resolveJoinAt(summary, role) != null
  );
}

/** Derives admin operational status from lifecycle + aggregated call summary. */
export function deriveActiveSessionOperationalStatus(
  session: Pick<AdminSessionSummary, 'lifecycleStatus' | 'startsAt' | 'endsAt'>,
  summary: CallTrackingSummary | null,
  now: Date = new Date(),
): ActiveSessionOperationalStatus {
  const call = callTrackingVm(summary, 'externalMeeting');
  const nowMs = now.getTime();

  if (summary?.callEndedAt) {
    const endedMs = summary.callEndedAt.getTime();
    if (nowMs - endedMs <= ACTIVE_SESSION_RECENTLY_ENDED_MS) {
      return ActiveSessionOperationalStatus.RecentlyEnded;
    }
  }

  if (
    session.lifecycleStatus === SessionLifecycleStatus.Completed ||
    session.lifecycleStatus === SessionLifecycleStatus.Incomplete
  ) {
    const endMs = session.endsAt?.getTime() ?? session.startsAt.getTime();
    if (nowMs - endMs <= ACTIVE_SESSION_RECENTLY_ENDED_MS) {
      return ActiveSessionOperationalStatus.RecentlyEnded;
    }
  }

  if (summary?.teacherNoShow || summary?.studentNoShow) {
    return ActiveSessionOperationalStatus.NoShowCandidate;
  }

  if (summary && !summary.actualCallStartedAt && session.startsAt.getTime() <= nowMs) {
    const teacherJoined = roleJoined(summary, 'teacher');
    const studentJoined = roleJoined(summary, 'student');
    if (!teacherJoined && !studentJoined) {
      return ActiveSessionOperationalStatus.NoShowCandidate;
    }
  }

  if (
    summary &&
    summary.actualCallStartedAt &&
    !summary.callEndedAt &&
    (summary.reconnectCount > 0 || summary.interruptionCount > 0)
  ) {
    return ActiveSessionOperationalStatus.InterruptedReconnecting;
  }

  if (
    (summary?.actualCallStartedAt && !summary.callEndedAt) ||
    session.lifecycleStatus === SessionLifecycleStatus.InProgress
  ) {
    return ActiveSessionOperationalStatus.Live;
  }

  if (summary) {
    const teacherJoined = roleJoined(summary, 'teacher');
    const studentJoined = roleJoined(summary, 'student');
    if (teacherJoined && !studentJoined) {
      return ActiveSessionOperationalStatus.WaitingForStudent;
    }
    if (studentJoined && !teacherJoined) {
      return ActiveSessionOperationalStatus.WaitingForTeacher;
    }
    if (summary.firstJoinAt && !summary.actualCallStartedAt) {
      if (summary.firstJoinRole === 'teacher') {
        return ActiveSessionOperationalStatus.WaitingForStudent;
      }
      if (summary.firstJoinRole === 'student') {
        return ActiveSessionOperationalStatus.WaitingForTeacher;
      }
    }
  }

  if (
    session.lifecycleStatus === SessionLifecycleStatus.Scheduled ||
    session.lifecycleStatus === SessionLifecycleStatus.Confirmed ||
    session.lifecycleStatus === SessionLifecycleStatus.Rescheduled ||
    session.lifecycleStatus === SessionLifecycleStatus.PendingPayment
  ) {
    if (session.startsAt.getTime() > nowMs) {
      return ActiveSessionOperationalStatus.ScheduledStartingSoon;
    }
    return ActiveSessionOperationalStatus.WaitingForTeacher;
  }

  if (call?.actualCallEndedAt) {
    return ActiveSessionOperationalStatus.RecentlyEnded;
  }

  return ActiveSessionOperationalStatus.ScheduledStartingSoon;
}

export function enrichActiveSessionRow(
  session: AdminSessionSummary,
  summary: CallTrackingSummary | null,
  now: Date = new Date(),
): ActiveSessionEnrichment {
  const call = callTrackingVm(summary, session.callType);
  const operationalStatus = deriveActiveSessionOperationalStatus(session, summary, now);
  return {
    operationalStatus,
    callPhase: resolveSessionCallPhase(session.lifecycleStatus, call),
    teacherJoinStatus: resolveParticipantJoinStatus(call, 'teacher'),
    studentJoinStatus: resolveParticipantJoinStatus(call, 'student'),
    whoJoinedFirst: summary?.firstJoinRole ?? '—',
    teacherLate: summary?.teacherLate === true,
    studentLate: summary?.studentLate === true,
    teacherNoShow: summary?.teacherNoShow ?? false,
    studentNoShow: summary?.studentNoShow ?? false,
    connectedMinutes: call?.connectedMinutes ?? 0,
    reconnectCount: summary?.reconnectCount ?? 0,
    interruptionCount: summary?.interruptionCount ?? 0,
    trackingUpdatedAt: summary?.updatedAt ?? null,
  };
}
