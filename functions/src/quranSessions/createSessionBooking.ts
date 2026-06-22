import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { legacyStatusForLifecycle, nowServer } from "./sessionLifecycleService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { recordTerminalTransition } from "./metricsAggregationService";

interface CreateSessionBookingRequest {
  teacherId: string;
  slotId: string;
  startsAt: string;
  endsAt: string;
  callType: "externalMeeting" | "voiceCall" | "videoCall";
  pricingType: "free" | "fixedPerSession" | "subscription";
  paymentReference?: string;
  studentNote?: string;
}

export const createSessionBooking = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const data = request.data as CreateSessionBookingRequest;
    if (!data.teacherId || !data.slotId || !data.startsAt || !data.endsAt) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const db = getFirestore();
    const studentId = request.auth.uid;
    const startsAt = Timestamp.fromDate(new Date(data.startsAt));
    const endsAt = Timestamp.fromDate(new Date(data.endsAt));

    const bookingRef = db.collection("quran_bookings").doc();
    const sessionRef = db.collection("quran_sessions").doc();
    const lockRef = db.collection("quran_slot_locks").doc(data.slotId);
    const now = nowServer();
    const lifecycleStatus = data.pricingType === "free" ? "scheduled" : "pending_payment";

    await db.runTransaction(async (tx) => {
      const lockSnap = await tx.get(lockRef);
      if (lockSnap.exists) {
        throw new HttpsError("already-exists", "Slot unavailable.");
      }
      tx.set(lockRef, {
        lockId: data.slotId,
        slotId: data.slotId,
        teacherId: data.teacherId,
        aggregateId: bookingRef.id,
        lockType: lifecycleStatus === "scheduled" ? "hard" : "soft",
        lockedAt: now,
        expiresAt:
          lifecycleStatus === "scheduled"
            ? Timestamp.fromDate(new Date("2099-01-01T00:00:00.000Z"))
            : Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
      });

      tx.set(bookingRef, {
        bookingId: bookingRef.id,
        aggregateId: bookingRef.id,
        sessionId: sessionRef.id,
        studentId,
        teacherId: data.teacherId,
        slotId: data.slotId,
        startsAt,
        endsAt,
        callType: data.callType,
        pricingType: data.pricingType,
        paymentReference: data.paymentReference ?? null,
        studentNote: data.studentNote ?? null,
        lifecycleStatus,
        status: legacyStatusForLifecycle(lifecycleStatus),
        createdAt: now,
        updatedAt: now,
      });

      tx.set(sessionRef, {
        sessionId: sessionRef.id,
        bookingId: bookingRef.id,
        aggregateId: bookingRef.id,
        studentId,
        teacherId: data.teacherId,
        startsAt,
        endsAt,
        callType: data.callType,
        lifecycleStatus: lifecycleStatus === "pending_payment" ? "scheduled" : lifecycleStatus,
        status: "scheduled",
        createdAt: now,
        updatedAt: now,
      });

      tx.set(db.collection("quran_session_events").doc(), {
        aggregateId: bookingRef.id,
        bookingId: bookingRef.id,
        sessionId: sessionRef.id,
        actorId: studentId,
        actorRole: "student",
        action: "create_booking",
        previousStatus: null,
        newStatus: lifecycleStatus,
        source: "mobileApp",
        timestamp: now,
      });
    });

    if (lifecycleStatus === "scheduled") {
      await recordTerminalTransition(db, {
        type: "booking_confirmed",
        teacherId: data.teacherId,
        studentId,
      });
      await enqueueSessionNotification(db, {
        sessionId: sessionRef.id,
        aggregateId: bookingRef.id,
        kind: "bookingConfirmed",
        recipientUserIds: [data.teacherId, studentId],
      });
    }

    return {
      bookingId: bookingRef.id,
      sessionId: sessionRef.id,
      lifecycleStatus,
      status: legacyStatusForLifecycle(lifecycleStatus),
    };
  },
);
