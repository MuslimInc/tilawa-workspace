import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import {
  financialExecutionStatus,
  PAYMENT_PROVIDER_ENABLED,
} from "./paymentProviderStatus";
import { requireAdmin } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";

interface ApproveSessionRefundRequest {
  bookingId: string;
  reason: string;
  amountUsd?: number;
  idempotencyKey?: string;
}

export const approveSessionRefund = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const data = request.data as ApproveSessionRefundRequest;
    if (!data.bookingId || !data.reason?.trim()) {
      throw new HttpsError(
        "invalid-argument",
        "bookingId and reason required.",
      );
    }

    const uid = requireAdmin(request);
    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const operationKey = buildOperationKey(
      "approve_refund",
      data.bookingId,
      data.idempotencyKey,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: uid,
        action: "approve_refund",
      },
      async (tx) => {
        const bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }
        const booking = bookingSnap.data() ?? {};
        const currentStatus = booking.lifecycleStatus as LifecycleStatus | undefined;

        const guard = validateTransition({
          currentStatus: currentStatus ?? null,
          action: "issue_refund",
          actor: "admin",
          reason: data.reason,
        });

        const sessionRef = sessionRefForBooking(db, booking);
        const refundRef = db.collection("quran_session_refunds").doc();
        const executionStatus = financialExecutionStatus();

        writeAggregateLifecycle(
          tx,
          { bookingRef, sessionRef },
          guard.to,
          {
            refundId: refundRef.id,
            refundExecutionStatus: executionStatus,
            refundReason: data.reason,
          },
          {
            refundId: refundRef.id,
            refundExecutionStatus: executionStatus,
          },
        );

        tx.set(refundRef, {
          refundId: refundRef.id,
          aggregateId: booking.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          sessionId: booking.sessionId ?? null,
          amountUsd: data.amountUsd ?? booking.amountPaidUsd ?? null,
          reason: data.reason,
          status: executionStatus,
          paymentProviderEnabled: PAYMENT_PROVIDER_ENABLED,
          approvedByActorId: uid,
          approvedByRole: "admin",
          createdAt: FieldValue.serverTimestamp(),
          completedAt:
            executionStatus === "executed"
              ? FieldValue.serverTimestamp()
              : null,
        });

        appendAuditEvent(tx, db, {
          aggregateId: booking.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          sessionId: booking.sessionId ?? null,
          refundId: refundRef.id,
          actorId: uid,
          actorRole: "admin",
          action: "approve_refund",
          previousStatus: currentStatus ?? null,
          newStatus: guard.to,
          reason: data.reason,
          refundExecutionStatus: executionStatus,
          source: "adminPanel",
        });

        return {
          bookingId: data.bookingId,
          refundId: refundRef.id,
          lifecycleStatus: guard.to,
          refundExecutionStatus: executionStatus,
        };
      },
    );

    if (!replayed) {
      const bookingSnap = await bookingRef.get();
      const booking = bookingSnap.data() ?? {};
      const studentId = (booking.studentId as string | undefined) ?? "";
      const sessionId = (booking.sessionId as string | undefined) ?? "";
      if (studentId && sessionId) {
        await enqueueSessionNotification(db, {
          sessionId,
          aggregateId: (booking.aggregateId as string) ?? data.bookingId,
          kind: "refundApproved",
          recipientUserIds: [studentId],
          payload: {
            reason: data.reason,
            refundExecutionStatus: result.refundExecutionStatus,
          },
        });
      }
    }

    return result;
  },
);
