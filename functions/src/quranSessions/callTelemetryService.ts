import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

export const CALL_TRACKING_LATE_GRACE_MINUTES = 5;
export const CALL_TRACKING_NO_SHOW_WINDOW_MINUTES = 15;

export type CallTelemetryEventType =
  | "joinRequested"
  | "joinSucceeded"
  | "joinFailed"
  | "participantConnected"
  | "participantDisconnected"
  | "reconnect"
  | "network"
  | "leave"
  | "callEnded";

export type CallParticipantRole = "teacher" | "student";

export interface RecordCallTelemetryEventInput {
  sessionId: string;
  eventId: string;
  eventType: CallTelemetryEventType;
  actorId: string;
  actorRole: CallParticipantRole;
  clientTimestampMs?: number;
  reasonCode?: string;
  remoteParticipantId?: string;
  networkQuality?: string;
  metadata?: Record<string, unknown>;
}

export interface CallTrackingAggregate {
  sessionId: string;
  scheduledStartsAt: Timestamp | null;
  firstJoinRole: CallParticipantRole | null;
  firstJoinAt: Timestamp | null;
  secondJoinRole: CallParticipantRole | null;
  secondJoinAt: Timestamp | null;
  actualCallStartedAt: Timestamp | null;
  teacherLate: boolean | null;
  studentLate: boolean | null;
  lateGraceMinutes: number;
  bothParticipantsConnectedSeconds: number;
  reconnectCount: number;
  interruptionCount: number;
  teacherNoShow: boolean;
  studentNoShow: boolean;
  noShowWindowMinutes: number;
  callEndedAt: Timestamp | null;
  updatedAt: FirebaseFirestore.FieldValue;
}

interface MutableTrackingState {
  scheduledStartsAt: Timestamp | null;
  firstJoinRole: CallParticipantRole | null;
  firstJoinAt: Timestamp | null;
  secondJoinRole: CallParticipantRole | null;
  secondJoinAt: Timestamp | null;
  actualCallStartedAt: Timestamp | null;
  teacherLate: boolean | null;
  studentLate: boolean | null;
  bothParticipantsConnectedSeconds: number;
  reconnectCount: number;
  interruptionCount: number;
  callEndedAt: Timestamp | null;
  bothConnectedSinceMs: number | null;
  teacherConnected: boolean;
  studentConnected: boolean;
  teacherEverConnected: boolean;
  studentEverConnected: boolean;
}

function emptyTrackingState(
  scheduledStartsAt: Timestamp | null,
): MutableTrackingState {
  return {
    scheduledStartsAt,
    firstJoinRole: null,
    firstJoinAt: null,
    secondJoinRole: null,
    secondJoinAt: null,
    actualCallStartedAt: null,
    teacherLate: null,
    studentLate: null,
    bothParticipantsConnectedSeconds: 0,
    reconnectCount: 0,
    interruptionCount: 0,
    callEndedAt: null,
    bothConnectedSinceMs: null,
    teacherConnected: false,
    studentConnected: false,
    teacherEverConnected: false,
    studentEverConnected: false,
  };
}

function asTimestamp(value: unknown): Timestamp | null {
  if (value instanceof Timestamp) {
    return value;
  }
  if (
    value &&
    typeof value === "object" &&
    "toDate" in value &&
    typeof (value as { toDate: () => Date }).toDate === "function"
  ) {
    return value as Timestamp;
  }
  return null;
}

function isLateJoin(
  scheduledStartsAt: Timestamp | null,
  joinedAtMs: number,
): boolean | null {
  if (!scheduledStartsAt) {
    return null;
  }
  const graceMs = CALL_TRACKING_LATE_GRACE_MINUTES * 60 * 1000;
  return joinedAtMs > scheduledStartsAt.toMillis() + graceMs;
}

/**
 * A participant is a no-show when they never connected AND the no-show window
 * (`scheduledStartsAt + 15min`) has elapsed as of `nowMs`. Before the window
 * expires, absence is pending, not a no-show.
 */
function isNoShow(
  scheduledStartsAt: Timestamp | null,
  everConnected: boolean,
  nowMs: number,
): boolean {
  if (everConnected) {
    return false;
  }
  if (!scheduledStartsAt) {
    return false;
  }
  const windowMs = CALL_TRACKING_NO_SHOW_WINDOW_MINUTES * 60 * 1000;
  return nowMs > scheduledStartsAt.toMillis() + windowMs;
}

function maybeStartBothConnected(
  state: MutableTrackingState,
  nowMs: number,
): void {
  if (!state.teacherConnected || !state.studentConnected) {
    return;
  }
  if (state.bothConnectedSinceMs == null) {
    state.bothConnectedSinceMs = nowMs;
    state.actualCallStartedAt = Timestamp.fromMillis(nowMs);
  }
}

function accumulateConnectedDuration(
  state: MutableTrackingState,
  nowMs: number,
): void {
  if (state.bothConnectedSinceMs == null) {
    return;
  }
  const deltaSeconds = Math.max(
    0,
    Math.floor((nowMs - state.bothConnectedSinceMs) / 1000),
  );
  state.bothParticipantsConnectedSeconds += deltaSeconds;
  state.bothConnectedSinceMs = null;
}

export function applyCallTelemetryEvent(
  state: MutableTrackingState,
  input: RecordCallTelemetryEventInput,
  serverNowMs: number,
): void {
  const joinedAtMs = input.clientTimestampMs ?? serverNowMs;

  switch (input.eventType) {
    case "joinRequested":
      break;
    case "joinSucceeded":
      if (!state.firstJoinRole) {
        state.firstJoinRole = input.actorRole;
        state.firstJoinAt = Timestamp.fromMillis(joinedAtMs);
        const late = isLateJoin(state.scheduledStartsAt, joinedAtMs);
        if (input.actorRole === "teacher") {
          state.teacherLate = late;
        } else {
          state.studentLate = late;
        }
      } else if (
        !state.secondJoinRole &&
        state.firstJoinRole !== input.actorRole
      ) {
        state.secondJoinRole = input.actorRole;
        state.secondJoinAt = Timestamp.fromMillis(joinedAtMs);
        const late = isLateJoin(state.scheduledStartsAt, joinedAtMs);
        if (input.actorRole === "teacher") {
          state.teacherLate = late;
        } else {
          state.studentLate = late;
        }
      }
      if (input.actorRole === "teacher") {
        state.teacherConnected = true;
        state.teacherEverConnected = true;
      } else {
        state.studentConnected = true;
        state.studentEverConnected = true;
      }
      maybeStartBothConnected(state, joinedAtMs);
      break;
    case "participantConnected":
      if (input.actorRole === "teacher") {
        state.teacherConnected = true;
        state.teacherEverConnected = true;
      } else {
        state.studentConnected = true;
        state.studentEverConnected = true;
      }
      maybeStartBothConnected(state, serverNowMs);
      break;
    case "participantDisconnected":
      accumulateConnectedDuration(state, serverNowMs);
      if (input.actorRole === "teacher") {
        state.teacherConnected = false;
      } else {
        state.studentConnected = false;
      }
      break;
    case "reconnect":
      state.reconnectCount += 1;
      // A reconnect after the call has already started is an interruption;
      // a reconnect while still waiting for the second participant is not.
      if (state.actualCallStartedAt) {
        state.interruptionCount += 1;
      }
      break;
    case "network":
    case "joinFailed":
      break;
    case "leave":
      accumulateConnectedDuration(state, serverNowMs);
      if (input.actorRole === "teacher") {
        state.teacherConnected = false;
      } else {
        state.studentConnected = false;
      }
      break;
    case "callEnded":
      accumulateConnectedDuration(state, serverNowMs);
      state.callEndedAt = Timestamp.fromMillis(serverNowMs);
      state.teacherConnected = false;
      state.studentConnected = false;
      break;
    default:
      break;
  }
}

export function toCallTrackingAggregate(
  sessionId: string,
  state: MutableTrackingState,
  nowMs: number,
): CallTrackingAggregate {
  return {
    sessionId,
    scheduledStartsAt: state.scheduledStartsAt,
    firstJoinRole: state.firstJoinRole,
    firstJoinAt: state.firstJoinAt,
    secondJoinRole: state.secondJoinRole,
    secondJoinAt: state.secondJoinAt,
    actualCallStartedAt: state.actualCallStartedAt,
    teacherLate: state.teacherLate,
    studentLate: state.studentLate,
    lateGraceMinutes: CALL_TRACKING_LATE_GRACE_MINUTES,
    bothParticipantsConnectedSeconds: state.bothParticipantsConnectedSeconds,
    reconnectCount: state.reconnectCount,
    interruptionCount: state.interruptionCount,
    teacherNoShow: isNoShow(
      state.scheduledStartsAt,
      state.teacherEverConnected,
      nowMs,
    ),
    studentNoShow: isNoShow(
      state.scheduledStartsAt,
      state.studentEverConnected,
      nowMs,
    ),
    noShowWindowMinutes: CALL_TRACKING_NO_SHOW_WINDOW_MINUTES,
    callEndedAt: state.callEndedAt,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function loadMutableTrackingState(
  existing: Record<string, unknown> | undefined,
  scheduledStartsAt: Timestamp | null,
): MutableTrackingState {
  if (!existing) {
    return emptyTrackingState(scheduledStartsAt);
  }
  return {
    scheduledStartsAt:
      asTimestamp(existing.scheduledStartsAt) ?? scheduledStartsAt,
    firstJoinRole: (existing.firstJoinRole as CallParticipantRole | null) ?? null,
    firstJoinAt: asTimestamp(existing.firstJoinAt),
    secondJoinRole:
      (existing.secondJoinRole as CallParticipantRole | null) ?? null,
    secondJoinAt: asTimestamp(existing.secondJoinAt),
    actualCallStartedAt: asTimestamp(existing.actualCallStartedAt),
    teacherLate: (existing.teacherLate as boolean | null) ?? null,
    studentLate: (existing.studentLate as boolean | null) ?? null,
    bothParticipantsConnectedSeconds:
      (existing.bothParticipantsConnectedSeconds as number | undefined) ?? 0,
    reconnectCount: (existing.reconnectCount as number | undefined) ?? 0,
    interruptionCount:
      (existing.interruptionCount as number | undefined) ?? 0,
    callEndedAt: asTimestamp(existing.callEndedAt),
    bothConnectedSinceMs: null,
    teacherConnected: false,
    studentConnected: false,
    // Reconstructed from persisted join roles: a recorded join means the
    // participant connected at least once during the session.
    teacherEverConnected:
      existing.firstJoinRole === "teacher" ||
      existing.secondJoinRole === "teacher",
    studentEverConnected:
      existing.firstJoinRole === "student" ||
      existing.secondJoinRole === "student",
  };
}

export async function recordCallTelemetryEventInTransaction(
  db: Firestore,
  input: RecordCallTelemetryEventInput,
  serverNowMs: number,
): Promise<{ replayed: boolean }> {
  const sessionRef = db.collection("quran_sessions").doc(input.sessionId);
  const trackingRef = sessionRef.collection("callTracking").doc("summary");
  const eventRef = sessionRef.collection("call_events").doc(input.eventId);

  return db.runTransaction(async (tx) => {
    const eventSnap = await tx.get(eventRef);
    if (eventSnap.exists) {
      return { replayed: true };
    }

    const sessionSnap = await tx.get(sessionRef);
    if (!sessionSnap.exists) {
      throw new Error("session_not_found");
    }
    const session = sessionSnap.data() ?? {};
    const scheduledStartsAt = asTimestamp(session.startsAt);

    const trackingSnap = await tx.get(trackingRef);
    const state = loadMutableTrackingState(
      trackingSnap.data(),
      scheduledStartsAt,
    );

    applyCallTelemetryEvent(state, input, serverNowMs);

    tx.set(eventRef, {
      eventId: input.eventId,
      sessionId: input.sessionId,
      eventType: input.eventType,
      actorId: input.actorId,
      actorRole: input.actorRole,
      clientTimestampMs: input.clientTimestampMs ?? null,
      reasonCode: input.reasonCode ?? null,
      remoteParticipantId: input.remoteParticipantId ?? null,
      networkQuality: input.networkQuality ?? null,
      metadata: input.metadata ?? {},
      recordedAt: FieldValue.serverTimestamp(),
    });

    tx.set(
      trackingRef,
      toCallTrackingAggregate(input.sessionId, state, serverNowMs),
      { merge: true },
    );

    // Denormalize hasActiveCall onto the booking doc so admin active-sessions
    // can find sessions with live calls without scanning all bookings or
    // depending on the scheduled startsAt time window. Early joins (before
    // startsAt) are correctly surfaced because the signal comes from call
    // tracking, not the schedule.
    const bookingId = (session.bookingId as string | undefined) ?? "";
    if (bookingId) {
      const hasActiveCall =
        state.actualCallStartedAt != null && state.callEndedAt == null;
      tx.update(db.collection("quran_bookings").doc(bookingId), {
        hasActiveCall,
        callTrackingUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    return { replayed: false };
  });
}
