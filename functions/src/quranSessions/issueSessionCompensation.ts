import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { nowServer } from "./sessionLifecycleService";
import { enqueueSessionNotification } from "./notificationOutboxService";

interface IssueSessionCompensationRequest {
  bookingId: string;
  compensationType: "restore_credit" | "wallet_credit" | "payment_refund";
  amountUsd?: number;
  reason: string;
}

export const issueSessionCompensation = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError("unauthenticated", "Authentication required.");
    if (!request.auth.token.admin) throw new HttpsError("permission-denied", "Admin access required.");

    const data = request.data as IssueSessionCompensationRequest;
    if (!data.bookingId || !data.compensationType || !data.reason) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }
    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const now = nowServer();
    const compensationRef = db.collection("quran_session_compensations").doc();

    let studentId = "";
    let sessionId = "";

    await db.runTransaction(async (tx) => {
      const bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) throw new HttpsError("not-found", "Booking not found.");
      const booking = bookingSnap.data() ?? {};
      studentId = (booking.studentId as string | undefined) ?? "";
      sessionId = (booking.sessionId as string | undefined) ?? "";
      tx.set(
        compensationRef,
        {
          compensationId: compensationRef.id,
          aggregateId: booking.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          type: data.compensationType,
          status: "completed",
          policyRuleId: "admin_manual",
          amountUsd: data.amountUsd ?? null,
          issuedByActorId: request.auth?.uid,
          issuedByRole: "admin",
          createdAt: now,
          completedAt: now,
        },
        { merge: true },
      );
      tx.set(
        bookingRef,
        { lifecycleStatus: "compensated", updatedAt: now },
        { merge: true },
      );
      if (sessionId) {
        tx.set(
          db.collection("quran_sessions").doc(sessionId),
          { lifecycleStatus: "compensated", updatedAt: now },
          { merge: true },
        );
      }
      tx.set(db.collection("quran_session_events").doc(), {
        aggregateId: booking.aggregateId ?? data.bookingId,
        bookingId: data.bookingId,
        sessionId: booking.sessionId ?? null,
        actorId: request.auth?.uid,
        actorRole: "admin",
        action: "issue_compensation",
        previousStatus: booking.lifecycleStatus ?? null,
        newStatus: "compensated",
        reason: data.reason,
        source: "adminPanel",
        timestamp: now,
      });
    });

    if (studentId && sessionId) {
      await enqueueSessionNotification(db, {
        sessionId,
        aggregateId: data.bookingId,
        kind: "compensationIssued",
        recipientUserIds: [studentId],
        payload: {
          compensationType: data.compensationType,
          amountUsd: data.amountUsd ?? null,
          reason: data.reason,
        },
      });
    }

    return { bookingId: data.bookingId, compensationId: compensationRef.id };
  },
);
