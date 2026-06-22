import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { nowServer } from "./sessionLifecycleService";

interface ConfirmSessionRescheduleRequest {
  requestId: string;
  accept: boolean;
  actorRole?: "student" | "teacher" | "admin";
}

export const confirmSessionReschedule = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const data = request.data as ConfirmSessionRescheduleRequest;
    if (!data.requestId) {
      throw new HttpsError("invalid-argument", "requestId required.");
    }
    const db = getFirestore();
    const reqRef = db.collection("quran_reschedule_requests").doc(data.requestId);
    const now = nowServer();

    await db.runTransaction(async (tx) => {
      const reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw new HttpsError("not-found", "Request not found.");
      const reqData = reqSnap.data() ?? {};
      const bookingId = reqData.bookingId as string;
      const bookingRef = db.collection("quran_bookings").doc(bookingId);
      const bookingSnap = await tx.get(bookingRef);
      const booking = bookingSnap.data() ?? {};

      if (data.accept) {
        const newSlotId = reqData.newSlotId as string;
        const lockRef = db.collection("quran_slot_locks").doc(newSlotId);
        const lockSnap = await tx.get(lockRef);
        if (lockSnap.exists) {
          throw new HttpsError("already-exists", "Target slot unavailable.");
        }
        const oldSlotId = reqData.oldSlotId as string;
        tx.delete(db.collection("quran_slot_locks").doc(oldSlotId));
        tx.set(lockRef, {
          lockId: newSlotId,
          slotId: newSlotId,
          teacherId: booking.teacherId,
          aggregateId: reqData.aggregateId,
          lockType: "hard",
          lockedAt: now,
        });
        tx.set(
          bookingRef,
          {
            slotId: newSlotId,
            startsAt: reqData.newStartsAt,
            lifecycleStatus: "scheduled",
            updatedAt: now,
          },
          { merge: true },
        );
      } else {
        tx.set(bookingRef, { lifecycleStatus: "scheduled", updatedAt: now }, { merge: true });
      }

      tx.set(
        reqRef,
        {
          status: data.accept ? "accepted" : "rejected",
          respondedByUserId: request.auth?.uid,
          respondedByRole: data.actorRole ?? "student",
          respondedAt: now,
        },
        { merge: true },
      );
      tx.set(db.collection("quran_session_events").doc(), {
        aggregateId: reqData.aggregateId,
        bookingId,
        sessionId: booking.sessionId ?? null,
        actorId: request.auth?.uid,
        actorRole: data.actorRole ?? "student",
        action: data.accept ? "confirm_reschedule" : "reject_reschedule",
        previousStatus: "rescheduled",
        newStatus: "scheduled",
        source: data.actorRole === "admin" ? "adminPanel" : "mobileApp",
        timestamp: now,
      });
    });

    return { requestId: data.requestId, accepted: data.accept };
  },
);
