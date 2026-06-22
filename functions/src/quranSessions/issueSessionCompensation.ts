import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  issueCompensationRecord,
  type CompensationType,
} from "./financialLedgerService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { requireAdmin } from "./sessionAuth";

interface IssueSessionCompensationRequest {
  bookingId: string;
  compensationType: CompensationType | "payment_refund";
  amountUsd?: number;
  reason: string;
  idempotencyKey?: string;
}

export const issueSessionCompensation = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const uid = requireAdmin(request);
    const data = request.data as IssueSessionCompensationRequest;
    if (!data.bookingId || !data.compensationType || !data.reason?.trim()) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }
    if (data.compensationType === "payment_refund") {
      throw new HttpsError(
        "invalid-argument",
        "Use approveSessionRefund for payment refunds.",
      );
    }
    const compensationType: CompensationType = data.compensationType;

    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const operationKey = buildOperationKey(
      "issue_compensation",
      data.bookingId,
      data.idempotencyKey ?? data.compensationType,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: uid,
        action: "issue_compensation",
      },
      async (tx) => {
        const bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }
        const booking = bookingSnap.data() ?? {};

        const ledger = issueCompensationRecord({
          tx,
          db,
          bookingRef,
          booking,
          bookingId: data.bookingId,
          compensationType,
          reason: data.reason,
          amountUsd: data.amountUsd ?? null,
          actorId: uid,
          actorRole: "admin",
          auditAction: "issue_compensation",
          auditSource: "adminPanel",
        });

        return {
          bookingId: data.bookingId,
          compensationId: ledger.compensationId,
          lifecycleStatus: ledger.lifecycleStatus,
          studentId: ledger.studentId,
          sessionId: ledger.sessionId,
          compensationExecutionStatus: ledger.compensationExecutionStatus,
        };
      },
    );

    if (!replayed && result.studentId && result.sessionId) {
      await enqueueSessionNotification(db, {
        sessionId: result.sessionId,
        aggregateId: data.bookingId,
        kind: "compensationIssued",
        recipientUserIds: [result.studentId],
        payload: {
          compensationType: data.compensationType,
          amountUsd: data.amountUsd ?? null,
          reason: data.reason,
          compensationExecutionStatus: result.compensationExecutionStatus,
        },
      });
    }

    return {
      bookingId: result.bookingId,
      compensationId: result.compensationId,
      compensationExecutionStatus: result.compensationExecutionStatus,
    };
  },
);
