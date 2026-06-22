import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import {
  appendAuditEvent,
} from "./aggregateWriteService";
import { lifecycleError } from "./lifecycleErrors";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import {
  assertPaidBookingAllowed,
  PAYMENT_PROVIDER_ENABLED,
} from "./paymentProviderStatus";
import { requireAuthenticatedUid } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import {
  legacyStatusForLifecycle,
  nowServer,
} from "./sessionLifecycleService";

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
    const studentId = requireAuthenticatedUid(request);
    const data = request.data as CreateSessionBookingRequest;
    if (!data.teacherId || !data.slotId || !data.startsAt || !data.endsAt) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    try {
      assertPaidBookingAllowed(data.pricingType);
    } catch {
      throw lifecycleError(
        "payment_provider_unavailable",
        "Paid bookings are disabled until payment provider is configured.",
        { pricingType: data.pricingType },
      );
    }

    if (
      data.pricingType !== "free" &&
      !data.paymentReference?.trim() &&
      PAYMENT_PROVIDER_ENABLED
    ) {
      throw new HttpsError(
        "invalid-argument",
        "paymentReference required for paid bookings.",
      );
    }

    const db = getFirestore();
    const startsAt = Timestamp.fromDate(new Date(data.startsAt));
    const endsAt = Timestamp.fromDate(new Date(data.endsAt));

    const bookingRef = db.collection("quran_bookings").doc();
    const sessionRef = db.collection("quran_sessions").doc();
    const lockRef = db.collection("quran_slot_locks").doc(data.slotId);
    const now = nowServer();

    const isFree = data.pricingType === "free";
    const bookingAction = isFree ? "confirm_free_booking" : "initiate_payment";
    const draftGuard = validateTransition({
      currentStatus: null,
      action: "create_draft",
      actor: "student",
    });
    const nextGuard = validateTransition({
      currentStatus: draftGuard.to,
      action: bookingAction,
      actor: isFree ? "student" : "student",
    });
    const lifecycleStatus = nextGuard.to;
    const sessionLifecycleStatus = lifecycleStatus;

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
        lifecycleStatus: sessionLifecycleStatus,
        status: legacyStatusForLifecycle(sessionLifecycleStatus),
        createdAt: now,
        updatedAt: now,
      });

      appendAuditEvent(tx, db, {
        aggregateId: bookingRef.id,
        bookingId: bookingRef.id,
        sessionId: sessionRef.id,
        actorId: studentId,
        actorRole: "student",
        action: "create_booking",
        previousStatus: null,
        newStatus: lifecycleStatus,
        source: "mobileApp",
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
