import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

import { appendAuditEvent, writeAggregateLifecycle } from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { lifecycleError } from "./lifecycleErrors";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import {
  PAYMENT_INTENTS_COLLECTION,
  PAYMENT_TRANSACTIONS_COLLECTION,
  paymentTransactionIdForConfirm,
} from "./payment/sandboxPaymentProvider";
import { resolvePaymentProvider } from "./payment/paymentProviderRegistry";
import { requireAuthenticatedUid } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import { legacyStatusForLifecycle } from "./sessionLifecycleService";
import type { BookingPaymentSnapshot } from "./payment/types";

interface ConfirmBookingPaymentRequest {
  bookingId: string;
  paymentReference: string;
  clientConfirmToken: string;
  idempotencyKey?: string;
}

interface ConfirmBookingPaymentResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
  status: string;
  paymentStatus: string;
  replayed: boolean;
}

export const confirmBookingPayment = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const studentId = requireAuthenticatedUid(request);
    const data = request.data as ConfirmBookingPaymentRequest;

    if (!data.bookingId?.trim() || !data.paymentReference?.trim()) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }
    if (!data.clientConfirmToken?.trim()) {
      throw new HttpsError("invalid-argument", "clientConfirmToken required.");
    }

    const db = getFirestore();
    const provider = resolvePaymentProvider();

    const precheck = await provider.confirmPayment({
      db,
      paymentReference: data.paymentReference.trim(),
      clientConfirmToken: data.clientConfirmToken.trim(),
      bookingId: data.bookingId.trim(),
      studentId,
    });

    if (precheck.alreadyConfirmed) {
      return {
        bookingId: precheck.bookingId,
        sessionId: precheck.sessionId,
        lifecycleStatus: precheck.lifecycleStatus,
        status: legacyStatusForLifecycle(
          precheck.lifecycleStatus as Parameters<typeof legacyStatusForLifecycle>[0],
        ),
        paymentStatus: precheck.paymentStatus,
        replayed: true,
      } satisfies ConfirmBookingPaymentResult;
    }

    const idempotencyKey =
      data.idempotencyKey?.trim() ||
      `confirm:${data.bookingId}:${data.paymentReference}`;
    const operationKey = buildOperationKey(
      "confirm_booking_payment",
      data.bookingId,
      idempotencyKey,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: studentId,
        action: "confirm_payment",
      },
      async (tx) => {
        const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
        const bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }
        const booking = bookingSnap.data() ?? {};
        if (booking.studentId !== studentId) {
          throw lifecycleError(
            "not_participant",
            "Only the booking student can confirm payment.",
          );
        }

        const currentStatus = booking.lifecycleStatus as string | undefined;
        if (currentStatus === "scheduled") {
          return {
            bookingId: data.bookingId,
            sessionId: (booking.sessionId as string) ?? "",
            lifecycleStatus: "scheduled",
            status: legacyStatusForLifecycle("scheduled"),
            paymentStatus: "captured",
            replayed: true,
          } satisfies ConfirmBookingPaymentResult;
        }
        if (currentStatus !== "pending_payment") {
          throw lifecycleError(
            "invalid_transition",
            "Booking is not awaiting payment.",
            { lifecycleStatus: currentStatus },
          );
        }

        const intentRef = db
          .collection(PAYMENT_INTENTS_COLLECTION)
          .doc(`sandbox_pi_${data.bookingId}`);
        const intentSnap = await tx.get(intentRef);
        if (!intentSnap.exists) {
          throw new HttpsError("not-found", "Payment intent not found.");
        }
        const intent = intentSnap.data() ?? {};
        if (intent.paymentReference !== data.paymentReference.trim()) {
          throw new HttpsError(
            "failed-precondition",
            "Payment reference mismatch.",
          );
        }
        if (intent.clientConfirmToken !== data.clientConfirmToken.trim()) {
          throw new HttpsError(
            "permission-denied",
            "Invalid payment confirmation token.",
          );
        }

        const guard = validateTransition({
          currentStatus: "pending_payment",
          action: "confirm_booking",
          actor: "system",
        });

        const sessionId = booking.sessionId as string;
        const sessionRef = db.collection("quran_sessions").doc(sessionId);
        const slotId = booking.slotId as string;
        const lockRef = db.collection("quran_slot_locks").doc(slotId);
        const now = Timestamp.now();

        const amount = (intent.amount as number) ?? 0;
        const currency = (intent.currency as string) ?? "EGP";
        const platformFee = (intent.platformFee as number) ?? 0;
        const teacherAmount = (intent.teacherAmount as number) ?? amount;
        const tax = (intent.tax as number) ?? 0;

        const paymentSnapshot: BookingPaymentSnapshot = {
          pricingType: "fixedPerSession",
          paymentStatus: "captured",
          paymentProvider: "sandbox",
          paymentReference: data.paymentReference.trim(),
          providerTransactionId: paymentTransactionIdForConfirm(data.bookingId),
          amount,
          currency,
          platformFee,
          teacherAmount,
          tax,
          capturedAt: now,
        };

        writeAggregateLifecycle(
          tx,
          { bookingRef, sessionRef },
          guard.to,
          {
            paymentStatus: "captured",
            paymentProvider: "sandbox",
            paymentReference: data.paymentReference.trim(),
            providerTransactionId: paymentSnapshot.providerTransactionId,
            amountPaidUsd: amount,
            priceAmount: amount,
            priceCurrency: currency,
            paymentSnapshot,
          },
          {
            paymentReference: data.paymentReference.trim(),
          },
        );

        tx.set(lockRef, {
          lockType: "hard",
          lockedAt: now,
          expiresAt: Timestamp.fromDate(new Date("2099-01-01T00:00:00.000Z")),
        }, { merge: true });

        tx.set(intentRef, {
          status: "succeeded",
          capturedAt: now,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        const txnId = paymentTransactionIdForConfirm(data.bookingId);
        tx.set(db.collection(PAYMENT_TRANSACTIONS_COLLECTION).doc(txnId), {
          paymentTransactionId: txnId,
          paymentIntentId: intent.paymentIntentId,
          bookingId: data.bookingId,
          providerTransactionId: paymentSnapshot.providerTransactionId,
          eventType: "captured",
          amount,
          currency,
          rawEventId: operationKey,
          createdAt: FieldValue.serverTimestamp(),
        });

        appendAuditEvent(tx, db, {
          aggregateId: data.bookingId,
          bookingId: data.bookingId,
          sessionId,
          actorId: studentId,
          actorRole: "system",
          action: "confirm_payment",
          previousStatus: "pending_payment",
          newStatus: guard.to,
          source: "mobileApp",
        });

        return {
          bookingId: data.bookingId,
          sessionId,
          lifecycleStatus: guard.to,
          status: legacyStatusForLifecycle(guard.to),
          paymentStatus: "captured",
          replayed: false,
        } satisfies ConfirmBookingPaymentResult;
      },
    );

    if (!replayed && result.lifecycleStatus === "scheduled") {
      const teacherId = (
        await db.collection("quran_bookings").doc(data.bookingId).get()
      ).data()?.teacherId as string;
      await recordTerminalTransition(db, {
        type: "booking_confirmed",
        teacherId,
        studentId,
      });
      await enqueueSessionNotification(db, {
        sessionId: result.sessionId,
        aggregateId: result.bookingId,
        kind: "bookingConfirmed",
        recipientUserIds: [teacherId, studentId],
      });
    }

    return { ...result, replayed };
  },
);
