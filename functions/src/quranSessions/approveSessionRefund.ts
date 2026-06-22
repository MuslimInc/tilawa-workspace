import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { issueRefundRecord } from "./financialLedgerService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { requireAdmin } from "./sessionAuth";

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

        const ledger = issueRefundRecord({
          tx,
          db,
          bookingRef,
          booking,
          bookingId: data.bookingId,
          reason: data.reason,
          amountUsd: data.amountUsd ?? null,
          actorId: uid,
          actorRole: "admin",
          auditAction: "approve_refund",
          auditSource: "adminPanel",
        });

        return {
          bookingId: data.bookingId,
          refundId: ledger.refundId,
          lifecycleStatus: ledger.lifecycleStatus,
          refundExecutionStatus: ledger.refundExecutionStatus,
          studentId: ledger.studentId,
          sessionId: ledger.sessionId,
        };
      },
    );

    if (!replayed && result.studentId && result.sessionId) {
      await enqueueSessionNotification(db, {
        sessionId: result.sessionId,
        aggregateId: data.bookingId,
        kind: "refundApproved",
        recipientUserIds: [result.studentId],
        payload: {
          reason: data.reason,
          refundExecutionStatus: result.refundExecutionStatus,
        },
      });
    }

    return {
      bookingId: result.bookingId,
      refundId: result.refundId,
      lifecycleStatus: result.lifecycleStatus,
      refundExecutionStatus: result.refundExecutionStatus,
    };
  },
);
