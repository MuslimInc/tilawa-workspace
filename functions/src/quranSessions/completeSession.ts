import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { recordTerminalTransition } from "./metricsAggregationService";
import {
  isAdmin,
  requireAuthenticatedUid,
  requireValidSessionEpochUnlessAdmin,
  resolveActorRole,
} from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import type { ActorRole } from "./sessionLifecycleGuard";

interface CompleteSessionRequest {
  sessionId: string;
  actorRole?: ActorRole;
  idempotencyKey?: string;
}

export const completeSession = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);
    const data = request.data as CompleteSessionRequest;
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

    const actor = isAdmin(request)
      ? ("admin" as const)
      : resolveActorRole(request, data.actorRole, participants);
    const guardActor =
      actor === "admin" ? "system" : actor;

    const operationKey = buildOperationKey(
      "complete_session",
      data.sessionId,
      data.idempotencyKey,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: request.auth!.uid,
        action: "complete_session",
      },
      async (tx) => {
        const freshSession = await tx.get(sessionRef);
        const fresh = freshSession.data() ?? {};
        const currentStatus = fresh.lifecycleStatus as LifecycleStatus | undefined;

        const guard = validateTransition({
          currentStatus: currentStatus ?? null,
          action: "complete_session",
          actor: guardActor,
        });

        writeAggregateLifecycle(
          tx,
          { bookingRef, sessionRef },
          guard.to,
          { completedAt: FieldValue.serverTimestamp() },
          { completedAt: FieldValue.serverTimestamp() },
        );

        appendAuditEvent(tx, db, {
          aggregateId: fresh.aggregateId ?? bookingId,
          bookingId,
          sessionId: data.sessionId,
          actorId: request.auth?.uid,
          actorRole: actor,
          action: "complete_session",
          previousStatus: currentStatus ?? null,
          newStatus: guard.to,
          source: actor === "admin" ? "adminPanel" : "mobileApp",
        });

        return {
          sessionId: data.sessionId,
          lifecycleStatus: guard.to,
          teacherId: (fresh.teacherId as string | undefined) ?? "",
          studentId: (fresh.studentId as string | undefined) ?? "",
        };
      },
    );

    if (!replayed) {
      const { teacherId, studentId } = result;
      if (teacherId && studentId) {
        await recordTerminalTransition(db, {
          type: "completed",
          teacherId,
          studentId,
        });
      }
    }

    return result;
  },
);
