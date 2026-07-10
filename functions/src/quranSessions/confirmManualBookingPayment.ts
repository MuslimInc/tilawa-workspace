import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { appendAuditEvent, writeAggregateLifecycle } from "./aggregateWriteService";
import {
  assertManualOffAppPaymentProvider,
  assertPendingManualPayment,
} from "./manualPaymentBookingGuards";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import type { BookingPaymentSnapshot } from "./payment/types";
import { requireAdmin } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import { legacyStatusForLifecycle } from "./sessionLifecycleService";
import { resolveTeacherProfileUserId } from "./teacherProfileUserId";

interface ConfirmManualBookingPaymentRequest {
  bookingId: string;
  note?: string;
}

interface ConfirmManualBookingPaymentResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
  status: string;
  paymentStatus: "captured";
  alreadyConfirmed: boolean;
}

export const confirmManualBookingPayment = onCall(
  { enforceAppCheck: false },
  async (request): Promise<ConfirmManualBookingPaymentResult> => {
    const adminUid = requireAdmin(request);
    const data = request.data as Partial<ConfirmManualBookingPaymentRequest>;
    const bookingId = data.bookingId?.trim();
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId required.");
    }

    const db = getFirestore();
    const result = await db.runTransaction(async (tx) => {
      const bookingRef = db.collection("quran_bookings").doc(bookingId);
      const bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) {
        throw new HttpsError("not-found", "Booking not found.");
      }
      const booking = bookingSnap.data() ?? {};
      assertManualOffAppPaymentProvider(booking);

      const sessionId = booking.sessionId as string | undefined;
      if (!sessionId) {
        throw new HttpsError("failed-precondition", "Booking has no session.");
      }
      if (booking.lifecycleStatus === "scheduled") {
        return {
          bookingId,
          sessionId,
          lifecycleStatus: "scheduled",
          status: legacyStatusForLifecycle("scheduled"),
          paymentStatus: "captured",
          alreadyConfirmed: true,
        } satisfies ConfirmManualBookingPaymentResult;
      }
      assertPendingManualPayment(booking);

      const guard = validateTransition({
        currentStatus: "pending_payment",
        action: "confirm_booking",
        actor: "admin",
      });
      const sessionRef = db.collection("quran_sessions").doc(sessionId);
      const slotId = booking.slotId as string | undefined;
      const now = Timestamp.now();
      const amount = (booking.priceAmount as number | undefined) ?? 0;
      const currency = (booking.priceCurrency as string | undefined) ?? "EGP";
      const paymentReference =
        (booking.paymentReference as string | undefined) ?? "";

      const paymentSnapshot: BookingPaymentSnapshot = {
        pricingType: "fixedPerSession",
        paymentStatus: "captured",
        paymentProvider: "manual_off_app",
        paymentReference,
        providerTransactionId: paymentReference,
        amount,
        currency,
        platformFee: 0,
        teacherAmount: amount,
        tax: 0,
        capturedAt: now,
      };

      writeAggregateLifecycle(
        tx,
        { bookingRef, sessionRef },
        guard.to,
        {
          paymentStatus: "captured",
          paymentProvider: "manual_off_app",
          paymentReference,
          providerTransactionId: paymentReference,
          amountPaidUsd: amount,
          paymentSnapshot,
          manualPaymentConfirmedAt: now,
          manualPaymentConfirmedBy: adminUid,
          manualPaymentNote: data.note?.trim() || null,
        },
        { paymentReference },
        booking,
      );

      if (slotId) {
        tx.set(
          db.collection("quran_slot_locks").doc(slotId),
          {
            lockType: "hard",
            lockedAt: now,
            expiresAt: Timestamp.fromDate(new Date("2099-01-01T00:00:00.000Z")),
          },
          { merge: true },
        );
      }

      appendAuditEvent(tx, db, {
        aggregateId: booking.aggregateId ?? bookingId,
        bookingId,
        sessionId,
        actorId: adminUid,
        actorRole: "admin",
        action: "confirm_manual_payment",
        previousStatus: "pending_payment",
        newStatus: guard.to,
        note: data.note?.trim() || null,
        source: "adminPanel",
      });

      return {
        bookingId,
        sessionId,
        lifecycleStatus: guard.to,
        status: legacyStatusForLifecycle(guard.to),
        paymentStatus: "captured",
        alreadyConfirmed: false,
      } satisfies ConfirmManualBookingPaymentResult;
    });

    if (!result.alreadyConfirmed) {
      const bookingSnap = await db.collection("quran_bookings").doc(bookingId).get();
      const booking = bookingSnap.data() ?? {};
      const teacherProfileId = booking.teacherId as string | undefined;
      const studentId = booking.studentId as string | undefined;
      if (teacherProfileId && studentId) {
        const teacherUserId = await resolveTeacherProfileUserId(
          db,
          teacherProfileId,
        );
        await recordTerminalTransition(db, {
          type: "booking_confirmed",
          teacherId: teacherUserId,
          studentId,
        });
        await enqueueSessionNotification(db, {
          sessionId: result.sessionId,
          aggregateId: result.bookingId,
          kind: "bookingConfirmed",
          recipientUserIds: [teacherUserId, studentId],
        });
      }
    }

    return result;
  },
);
