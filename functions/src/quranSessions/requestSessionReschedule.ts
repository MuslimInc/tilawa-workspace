import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { nowServer } from "./sessionLifecycleService";

interface RequestSessionRescheduleRequest {
  bookingId: string;
  newSlotId: string;
  newStartsAt: string;
  reason: string;
  actorRole?: "student" | "teacher";
}

export const requestSessionReschedule = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const data = request.data as RequestSessionRescheduleRequest;
    if (!data.bookingId || !data.newSlotId || !data.reason) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const now = nowServer();
    const expiresAt = Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
    const requestRef = db.collection("quran_reschedule_requests").doc();

    await db.runTransaction(async (tx) => {
      const bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) throw new HttpsError("not-found", "Booking not found.");
      const booking = bookingSnap.data() ?? {};
      tx.set(bookingRef, { lifecycleStatus: "rescheduled", updatedAt: now }, { merge: true });
      tx.set(requestRef, {
        requestId: requestRef.id,
        aggregateId: booking.aggregateId ?? data.bookingId,
        bookingId: data.bookingId,
        requestedByUserId: request.auth?.uid,
        requestedByRole: data.actorRole ?? "student",
        reason: data.reason,
        oldSlotId: booking.slotId,
        newSlotId: data.newSlotId,
        newStartsAt: Timestamp.fromDate(new Date(data.newStartsAt)),
        status: "pending",
        createdAt: now,
        expiresAt,
      });
      tx.set(db.collection("quran_session_events").doc(), {
        aggregateId: booking.aggregateId ?? data.bookingId,
        bookingId: data.bookingId,
        sessionId: booking.sessionId ?? null,
        actorId: request.auth?.uid,
        actorRole: data.actorRole ?? "student",
        action: "request_reschedule",
        previousStatus: booking.lifecycleStatus ?? null,
        newStatus: "rescheduled",
        reason: data.reason,
        source: "mobileApp",
        timestamp: now,
      });
    });
    return { bookingId: data.bookingId, requestId: requestRef.id, status: "pending" };
  },
);
