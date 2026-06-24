import { CallEvent, CallTrackingSummary } from '../../domain/entities/call-tracking.entity';
import { readTimestamp } from './quran-sessions.mapper';

export interface CallTrackingSummaryFirestoreDto {
  sessionId?: string;
  scheduledStartsAt?: unknown;
  firstJoinRole?: string | null;
  firstJoinAt?: unknown;
  secondJoinRole?: string | null;
  secondJoinAt?: unknown;
  actualCallStartedAt?: unknown;
  callEndedAt?: unknown;
  teacherLate?: boolean | null;
  studentLate?: boolean | null;
  lateGraceMinutes?: number;
  teacherNoShow?: boolean;
  studentNoShow?: boolean;
  noShowWindowMinutes?: number;
  bothParticipantsConnectedSeconds?: number;
  reconnectCount?: number;
  interruptionCount?: number;
  updatedAt?: unknown;
}

export interface CallEventFirestoreDto {
  eventType?: string;
  actorRole?: string;
  actorId?: string;
  reasonCode?: string | null;
  networkQuality?: string | null;
  remoteParticipantId?: string | null;
  recordedAt?: unknown;
  clientTimestampMs?: number | null;
}

/** Defaults assume not-late / not-no-show, never silently fabricating "late". */
export class CallTrackingMapper {
  static summaryFromFirestore(
    sessionId: string,
    dto: CallTrackingSummaryFirestoreDto,
  ): CallTrackingSummary {
    return {
      sessionId: dto.sessionId ?? sessionId,
      scheduledStartsAt: readTimestamp(dto.scheduledStartsAt),
      firstJoinRole: dto.firstJoinRole ?? null,
      firstJoinAt: readTimestamp(dto.firstJoinAt),
      secondJoinRole: dto.secondJoinRole ?? null,
      secondJoinAt: readTimestamp(dto.secondJoinAt),
      actualCallStartedAt: readTimestamp(dto.actualCallStartedAt),
      callEndedAt: readTimestamp(dto.callEndedAt),
      teacherLate: dto.teacherLate ?? null,
      studentLate: dto.studentLate ?? null,
      lateGraceMinutes: dto.lateGraceMinutes ?? 0,
      teacherNoShow: dto.teacherNoShow ?? false,
      studentNoShow: dto.studentNoShow ?? false,
      noShowWindowMinutes: dto.noShowWindowMinutes ?? 0,
      bothParticipantsConnectedSeconds:
        dto.bothParticipantsConnectedSeconds ?? 0,
      reconnectCount: dto.reconnectCount ?? 0,
      interruptionCount: dto.interruptionCount ?? 0,
      updatedAt: readTimestamp(dto.updatedAt),
    };
  }

  static eventFromFirestore(id: string, dto: CallEventFirestoreDto): CallEvent {
    return {
      id,
      eventType: dto.eventType ?? 'unknown',
      actorRole: dto.actorRole ?? 'system',
      actorId: dto.actorId ?? '',
      reasonCode: dto.reasonCode ?? null,
      networkQuality: dto.networkQuality ?? null,
      remoteParticipantId: dto.remoteParticipantId ?? null,
      recordedAt: readTimestamp(dto.recordedAt),
      clientTimestampMs: dto.clientTimestampMs ?? null,
    };
  }
}
