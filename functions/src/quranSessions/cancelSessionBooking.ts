import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { isAdmin, requireAuthenticatedUid, resolveActorRole } from "./sessionAuth";
import { cancelActionForRole, validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import type { ActorRole } from "./sessionLifecycleGuard";

interface CancelSessionBookingRequest {
  bookingId: string;
  reason: string;
  actorRole?: ActorRole;
  idempotencyKey?: string;
}

export const cancelSessionBooking = onCall(
  { enforceAppCheck: false },
  async (request) => {
    requireAuthenticatedUid(request);
    const data = request.data as CancelSessionBookingRequest;
    if (!data.bookingId || !data.reason?.trim()) {
      throw new HttpsError("invalid-argument", "bookingId and reason required.");
    }

    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }
    const booking = bookingSnap.data() ?? {};
    const participants = {
      studentId: (booking.studentId as string) ?? "",
      teacherId: (booking.teacherId as string) ?? "",
    };

    const claimedRole = data.actorRole ?? "student";
    if (claimedRole === "admin" && !isAdmin(request)) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    const actor = isAdmin(request) && claimedRole === "admin"
      ? "admin"
      : resolveActorRole(request, claimedRole, participants);
    const action = cancelActionForRole(actor);

    const operationKey = buildOperationKey(
      "cancel_session",
      data.bookingId,
      data.idempotencyKey,
    );

    const startsAtRaw = booking.startsAt;
    const sessionStartsAt =
      startsAtRaw instanceof Timestamp
        ? startsAtRaw.toDate()
        : typeof startsAtRaw === "string"
          ? new Date(startsAtRaw)
          : undefined;

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: request.auth!.uid,
        action: "cancel_session",
      },
      async (tx) => {
        const freshSnap = await tx.get(bookingRef);
        const fresh = freshSnap.data() ?? {};
        const currentStatus = fresh.lifecycleStatus as LifecycleStatus | undefined;

        const guard = validateTransition({
          currentStatus: currentStatus ?? null,
          action,
          actor,
          reason: data.reason,
          sessionStartsAt,
        });

        const sessionRef = sessionRefForBooking(db, fresh);
        writeAggregateLifecycle(
          tx,
          { bookingRef, sessionRef },
          guard.to,
          {
            cancellationReason: data.reason,
            cancelledAt: new Date(),
            cancelledByActorId: request.auth?.uid,
            cancelledByRole: actor,
          },
        );

        const slotId = fresh.slotId as string | undefined;
        if (slotId) {
          tx.delete(db.collection("quran_slot_locks").doc(slotId));
        }

        appendAuditEvent(tx, db, {
          aggregateId: fresh.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          sessionId: fresh.sessionId ?? null,
          actorId: request.auth?.uid ?? "system",
          actorRole: actor,
          action: "cancel_session",
          previousStatus: currentStatus ?? null,
          newStatus: guard.to,
          reason: data.reason,
          source: actor === "admin" ? "adminPanel" : "mobileApp",
        });

        return {
          bookingId: data.bookingId,
          lifecycleStatus: guard.to,
          sessionId: (fresh.sessionId as string | undefined) ?? "",
          teacherId: (fresh.teacherId as string | undefined) ?? "",
          studentId: (fresh.studentId as string | undefined) ?? "",
        };
      },
    );

    if (!replayed && result.sessionId) {
      if (result.lifecycleStatus === "cancelled_by_teacher") {
        await recordTerminalTransition(db, {
          type: "cancelled_by_teacher",
          teacherId: result.teacherId,
        });
      } else if (result.lifecycleStatus === "cancelled_by_student") {
        await recordTerminalTransition(db, {
          type: "cancelled_by_student",
          studentId: result.studentId,
        });
      }
      await enqueueSessionNotification(db, {
        sessionId: result.sessionId,
        aggregateId: data.bookingId,
        kind: "cancellation",
        recipientUserIds: [result.teacherId, result.studentId],
        payload: { reason: data.reason, actorRole: actor },
      });
    }

    return {
      bookingId: result.bookingId,
      lifecycleStatus: result.lifecycleStatus,
    };
  },
);
