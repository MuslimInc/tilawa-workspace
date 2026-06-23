import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { isAdmin, requireAuthenticatedUid, requireValidSessionEpochUnlessAdmin, resolveActorRole } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import { nowServer } from "./sessionLifecycleService";
import type { ActorRole } from "./sessionLifecycleGuard";

interface ConfirmSessionRescheduleRequest {
  requestId: string;
  accept: boolean;
  actorRole?: ActorRole;
  idempotencyKey?: string;
}

export const confirmSessionReschedule = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);
    const data = request.data as ConfirmSessionRescheduleRequest;
    if (!data.requestId) {
      throw new HttpsError("invalid-argument", "requestId required.");
    }

    const db = getFirestore();
    const reqRef = db.collection("quran_reschedule_requests").doc(data.requestId);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "Request not found.");
    }
    const reqData = reqSnap.data() ?? {};
    const bookingId = reqData.bookingId as string;
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

    const claimedRole = data.actorRole ?? "student";
    if (claimedRole === "admin" && !isAdmin(request)) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    const actor = isAdmin(request) && claimedRole === "admin"
      ? "admin"
      : resolveActorRole(request, claimedRole, participants);
    const guardActor =
      actor === "admin" ? "system" : actor;

    const operationKey = buildOperationKey(
      "confirm_reschedule",
      data.requestId,
      data.idempotencyKey ?? String(data.accept),
    );
    const now = nowServer();

    const { result } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: request.auth!.uid,
        action: "confirm_reschedule",
      },
      async (tx) => {
        const [freshReq, freshBooking] = await Promise.all([
          tx.get(reqRef),
          tx.get(bookingRef),
        ]);
        if (!freshReq.exists) {
          throw new HttpsError("not-found", "Request not found.");
        }
        const requestData = freshReq.data() ?? {};
        const bookingData = freshBooking.data() ?? {};
        const currentStatus = bookingData.lifecycleStatus as LifecycleStatus | undefined;

        if (currentStatus !== "rescheduled") {
          throw new HttpsError(
            "failed-precondition",
            "Booking is not awaiting reschedule confirmation.",
          );
        }

        const sessionRef = sessionRefForBooking(db, bookingData);

        if (data.accept) {
          const newSlotId = requestData.newSlotId as string;
          const lockRef = db.collection("quran_slot_locks").doc(newSlotId);
          const lockSnap = await tx.get(lockRef);
          if (lockSnap.exists) {
            throw new HttpsError("already-exists", "Target slot unavailable.");
          }

          validateTransition({
            currentStatus,
            action: "confirm_reschedule",
            actor: guardActor,
            reason: (requestData.reason as string | undefined) ?? "reschedule_confirmed",
            isTargetSlotAvailable: true,
            targetSlotId: newSlotId,
          });

          const oldSlotId = requestData.oldSlotId as string;
          tx.delete(db.collection("quran_slot_locks").doc(oldSlotId));
          tx.set(lockRef, {
            lockId: newSlotId,
            slotId: newSlotId,
            teacherId: bookingData.teacherId,
            aggregateId: requestData.aggregateId,
            lockType: "hard",
            lockedAt: now,
          });

          writeAggregateLifecycle(
            tx,
            { bookingRef, sessionRef },
            "scheduled",
            {
              slotId: newSlotId,
              startsAt: requestData.newStartsAt,
            },
            { startsAt: requestData.newStartsAt },
          );
        } else {
          writeAggregateLifecycle(tx, { bookingRef, sessionRef }, "scheduled");
        }

        tx.set(
          reqRef,
          {
            status: data.accept ? "accepted" : "rejected",
            respondedByUserId: request.auth?.uid,
            respondedByRole: actor,
            respondedAt: now,
          },
          { merge: true },
        );

        appendAuditEvent(tx, db, {
          aggregateId: requestData.aggregateId,
          bookingId,
          sessionId: bookingData.sessionId ?? null,
          actorId: request.auth?.uid,
          actorRole: actor,
          action: data.accept ? "confirm_reschedule" : "reject_reschedule",
          previousStatus: currentStatus ?? null,
          newStatus: "scheduled",
          source: actor === "admin" ? "adminPanel" : "mobileApp",
        });

        return { requestId: data.requestId, accepted: data.accept };
      },
    );

    return result;
  },
);
