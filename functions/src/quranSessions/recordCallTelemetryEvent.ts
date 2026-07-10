import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import {
  recordCallTelemetryEventInTransaction,
  type CallTelemetryEventType,
  type CallParticipantRole,
} from "./callTelemetryService";
import {
  requireAuthenticatedUid,
  requireParticipantOrAdmin,
  requireValidSessionEpochUnlessAdmin,
} from "./sessionAuth";
import {
  resolveTeacherProfileUserId,
  teacherUserIdFromDenormalizedSessionData,
} from "./teacherProfileUserId";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

const VALID_EVENT_TYPES = new Set<CallTelemetryEventType>([
  "joinRequested",
  "joinSucceeded",
  "joinFailed",
  "participantConnected",
  "participantDisconnected",
  "reconnect",
  "network",
  "leave",
  "callEnded",
]);

interface RecordCallTelemetryEventRequest {
  sessionId: string;
  eventId: string;
  eventType: CallTelemetryEventType;
  actorRole: CallParticipantRole;
  clientTimestampMs?: number;
  reasonCode?: string;
  remoteParticipantId?: string;
  networkQuality?: string;
  metadata?: Record<string, unknown>;
}

function isValidEventType(value: unknown): value is CallTelemetryEventType {
  return (
    typeof value === "string" &&
    VALID_EVENT_TYPES.has(value as CallTelemetryEventType)
  );
}

function isValidActorRole(value: unknown): value is CallParticipantRole {
  return value === "teacher" || value === "student";
}

/**
 * Records idempotent call telemetry and updates aggregated callTracking summary.
 */
export const recordCallTelemetryEvent = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);
    const data = request.data as RecordCallTelemetryEventRequest;

    if (!data.sessionId?.trim()) {
      throw new HttpsError("invalid-argument", "sessionId required.");
    }
    if (!data.eventId?.trim()) {
      throw new HttpsError("invalid-argument", "eventId required.");
    }
    if (!isValidEventType(data.eventType)) {
      throw new HttpsError("invalid-argument", "eventType invalid.");
    }
    if (!isValidActorRole(data.actorRole)) {
      throw new HttpsError("invalid-argument", "actorRole invalid.");
    }

    const db = getFirestore();
    const sessionRef = db.collection("quran_sessions").doc(data.sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      throw new HttpsError("not-found", "Session not found.");
    }
    const session = sessionSnap.data() ?? {};
    const studentId = (session.studentId as string | undefined) ?? "";
    const teacherId = (session.teacherId as string | undefined) ?? "";
    // Prefer the denormalized `teacherUserId` on the session doc (written by
    // createSessionBooking + createAdminTestQuranSession since P2.9) to avoid a
    // redundant teacher_profiles doc read on every telemetry event. Fall back
    // to a profile lookup only for legacy sessions that predate the field.
    const teacherUserId =
      teacherUserIdFromDenormalizedSessionData(session) ??
      (await resolveTeacherProfileUserId(db, teacherId));

    const { actor } = requireParticipantOrAdmin(
      request,
      {
        studentId,
        teacherId,
      },
      teacherUserId,
    );
    if (actor !== data.actorRole) {
      throw new HttpsError("permission-denied", "actorRole mismatch.");
    }

    try {
      const result = await recordCallTelemetryEventInTransaction(
        db,
        {
          sessionId: data.sessionId,
          eventId: data.eventId.trim(),
          eventType: data.eventType,
          actorId: uid,
          actorRole: data.actorRole,
          clientTimestampMs: data.clientTimestampMs,
          reasonCode: data.reasonCode,
          remoteParticipantId: data.remoteParticipantId,
          networkQuality: data.networkQuality,
          metadata: data.metadata,
          resolvedStudentId: studentId,
          resolvedTeacherUserId: teacherUserId,
          // Pass the session data already fetched for auth so the transaction
          // can skip a redundant `tx.get(sessionRef)` read.
          prefetchedSession: {
            bookingId: (session.bookingId as string | undefined) ?? "",
            startsAt: session.startsAt as Timestamp | undefined,
            endsAt: session.endsAt as Timestamp | undefined,
            lifecycleStatus: session.lifecycleStatus as string | undefined,
          },
        },
        Date.now(),
      );
      return { replayed: result.replayed };
    } catch (error) {
      if (error instanceof Error && error.message === "session_not_found") {
        throw new HttpsError("not-found", "Session not found.");
      }
      throw error;
    }
  },
);

export {
  applyCallTelemetryEvent,
  loadMutableTrackingState,
  recordCallTelemetryEventInTransaction,
} from "./callTelemetryService";
