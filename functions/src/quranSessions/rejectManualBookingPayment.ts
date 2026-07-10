import { onCall, HttpsError } from "firebase-functions/v2/https";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import { getFirestore } from "firebase-admin/firestore";
import {
  assertManualOffAppPaymentProvider,
  assertPendingManualPayment,
} from "./manualPaymentBookingGuards";
import { requireAdmin } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import { legacyStatusForLifecycle } from "./sessionLifecycleService";

interface RejectManualBookingPaymentRequest {
  bookingId: string;
  reason?: string;
}

interface RejectManualBookingPaymentResult {
  bookingId: string;
  lifecycleStatus: string;
  status: string;
  paymentStatus: "voided";
  alreadyRejected: boolean;
}

export const rejectManualBookingPayment = onCall(
  { enforceAppCheck: false },
  async (request): Promise<RejectManualBookingPaymentResult> => {
    const adminUid = requireAdmin(request);
    const data = request.data as Partial<RejectManualBookingPaymentRequest>;
    const bookingId = data.bookingId?.trim();
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId required.");
    }
    const reason = data.reason?.trim() || "Manual payment rejected.";

    const db = getFirestore();
    return db.runTransaction(async (tx) => {
      const bookingRef = db.collection("quran_bookings").doc(bookingId);
      const bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) {
        throw new HttpsError("not-found", "Booking not found.");
      }
      const booking = bookingSnap.data() ?? {};
      assertManualOffAppPaymentProvider(booking);

      if (booking.lifecycleStatus === "cancelled_by_admin") {
        return {
          bookingId,
          lifecycleStatus: "cancelled_by_admin",
          status: legacyStatusForLifecycle("cancelled_by_admin"),
          paymentStatus: "voided",
          alreadyRejected: true,
        } satisfies RejectManualBookingPaymentResult;
      }
      assertPendingManualPayment(booking);

      const guard = validateTransition({
        currentStatus: "pending_payment",
        action: "cancel_by_admin",
        actor: "admin",
        reason,
      });
      const sessionRef = sessionRefForBooking(db, booking);
      writeAggregateLifecycle(
        tx,
        { bookingRef, sessionRef },
        guard.to,
        {
          cancellationReason: reason,
          cancelledAt: new Date(),
          cancelledByActorId: adminUid,
          cancelledByRole: "admin",
          paymentStatus: "voided",
          manualPaymentRejectedAt: new Date(),
          manualPaymentRejectedBy: adminUid,
          manualPaymentRejectionReason: reason,
        },
        {},
        booking,
      );

      const slotId = booking.slotId as string | undefined;
      if (slotId) {
        tx.delete(db.collection("quran_slot_locks").doc(slotId));
      }

      appendAuditEvent(tx, db, {
        aggregateId: booking.aggregateId ?? bookingId,
        bookingId,
        sessionId: booking.sessionId ?? null,
        actorId: adminUid,
        actorRole: "admin",
        action: "reject_manual_payment",
        previousStatus: "pending_payment",
        newStatus: guard.to,
        reason,
        source: "adminPanel",
      });

      return {
        bookingId,
        lifecycleStatus: guard.to,
        status: legacyStatusForLifecycle(guard.to),
        paymentStatus: "voided",
        alreadyRejected: false,
      } satisfies RejectManualBookingPaymentResult;
    });
  },
);
