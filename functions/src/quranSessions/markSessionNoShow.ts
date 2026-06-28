import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { resolveTeacherProfileUserId, teacherUserIdFromDenormalizedSessionData } from "./teacherProfileUserId";
import {
  isAdmin,
  requireAuthenticatedUid,
  requireValidSessionEpochUnlessAdmin,
  resolveActorRole,
} from "./sessionAuth";
import {
  noShowActionForClassification,
  validateTransition,
} from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

type NoShowClassification =
  | "teacher_no_show"
  | "student_no_show"
  | "both_no_show";

interface MarkSessionNoShowRequest {
  sessionId: string;
  /** Primary contract field — admin + mobile must send this. */
  classification?: NoShowClassification;
  /** Used for authorization; teacher may omit classification (defaults student_no_show). */
  actorRole?: "student" | "teacher" | "admin" | "system";
  reason?: string;
  idempotencyKey?: string;
}

function resolveClassification(
  data: MarkSessionNoShowRequest,
  actor: "student" | "teacher" | "admin" | "system",
): NoShowClassification {
  if (data.classification) {
    return data.classification;
  }
  if (actor === "teacher") {
    return "student_no_show";
  }
  if (actor === "admin" || actor === "system") {
    throw new HttpsError(
      "invalid-argument",
      "classification required for admin/system no-show actions.",
    );
  }
  throw new HttpsError(
    "invalid-argument",
    "classification required.",
  );
}

export const markSessionNoShow = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);
    const data = request.data as MarkSessionNoShowRequest;
    if (!data.sessionId) {
      throw new HttpsError("invalid-argument", "sessionId required.");
    }

    const db = getFirestore();
    const sessionRef = db.collection("quran_sessions").doc(data.sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      throw new HttpsError("not-found", "Session not found.");
    }
    const session = sessionSnap.data() ?? {};
    const bookingId = session.bookingId as string;
    const bookingRef = db.collection("quran_bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }
    const booking = bookingSnap.data() ?? {};
    const participants = {
      studentId: (booking.studentId as string) ?? "",
      teacherId: (booking.teacherId as string) ?? "",
    };

    const teacherUserId =
      teacherUserIdFromDenormalizedSessionData(booking) ??
      (await resolveTeacherProfileUserId(db, participants.teacherId));
    const actor = isAdmin(request)
      ? ("admin" as const)
      : resolveActorRole(request, data.actorRole, participants, teacherUserId);
    const classification = resolveClassification(data, actor);
    const action = noShowActionForClassification(classification);

    const operationKey = buildOperationKey(
      "mark_no_show",
      data.sessionId,
      data.idempotencyKey ?? classification,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: request.auth!.uid,
        action: "mark_no_show",
      },
      async (tx) => {
        const freshSession = await tx.get(sessionRef);
        const fresh = freshSession.data() ?? {};
        const currentStatus = fresh.lifecycleStatus as LifecycleStatus | undefined;

        const guard = validateTransition({
          currentStatus: currentStatus ?? null,
          action,
          actor: actor === "admin" ? "admin" : actor,
          reason: data.reason,
        });

        writeAggregateLifecycle(
          tx,
          { bookingRef, sessionRef },
          guard.to,
        );

        appendAuditEvent(tx, db, {
          aggregateId: fresh.aggregateId ?? bookingId,
          bookingId,
          sessionId: data.sessionId,
          actorId: request.auth?.uid,
          actorRole: actor,
          action: "mark_no_show",
          previousStatus: currentStatus ?? null,
          newStatus: guard.to,
          reason: data.reason ?? null,
          classification,
          source: actor === "admin" ? "adminPanel" : "mobileApp",
        });

        return {
          sessionId: data.sessionId,
          lifecycleStatus: guard.to,
          classification,
        };
      },
    );

    if (!replayed) {
      const teacherId = session.teacherId as string | undefined;
      const studentId = session.studentId as string | undefined;
      if (teacherId && studentId) {
        const metricsType =
          classification === "teacher_no_show"
            ? ({ type: "teacher_no_show", teacherId } as const)
            : classification === "student_no_show"
              ? ({ type: "student_no_show", studentId } as const)
              : ({ type: "both_no_show", teacherId, studentId } as const);
        await recordTerminalTransition(db, metricsType);
        await enqueueSessionNotification(db, {
          sessionId: data.sessionId,
          aggregateId: (session.aggregateId as string | undefined) ?? bookingId,
          kind: "noShowMarked",
          recipientUserIds: [teacherUserId, studentId],
          payload: { classification },
        });
      }
    }

    return result;
  },
);
