import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  disputeStatusForResolution,
  initialDisputeRecord,
} from "./disputeTypes";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { lifecycleError } from "./lifecycleErrors";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { requireAdmin, requireParticipantOrAdmin } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";

interface OpenSessionDisputeRequest {
  bookingId: string;
  reason: string;
  evidenceMetadata?: Record<string, unknown>;
  idempotencyKey?: string;
}

export const openSessionDispute = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const data = request.data as OpenSessionDisputeRequest;
    if (!data.bookingId || !data.reason?.trim()) {
      throw new HttpsError(
        "invalid-argument",
        "bookingId and reason required.",
      );
    }

    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }
    const booking = bookingSnap.data() ?? {};
    const participants = {
      studentId: (booking.studentId as string) ?? "",
      teacherId: (booking.teacherId as string) ?? "",
    };
    const { uid, actor } = requireParticipantOrAdmin(request, participants);

    const operationKey = buildOperationKey(
      "open_dispute",
      data.bookingId,
      data.idempotencyKey,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: uid,
        action: "open_dispute",
      },
      async (tx) => {
        const freshBooking = await tx.get(bookingRef);
        const fresh = freshBooking.data() ?? {};
        const currentStatus = fresh.lifecycleStatus as LifecycleStatus | undefined;

        const guard = validateTransition({
          currentStatus: currentStatus ?? null,
          action: "open_dispute",
          actor,
          reason: data.reason,
        });

        const sessionRef = sessionRefForBooking(db, fresh);
        const disputeRef = db.collection("quran_session_disputes").doc();

        writeAggregateLifecycle(tx, { bookingRef, sessionRef }, guard.to);

        tx.set(
          disputeRef,
          initialDisputeRecord({
            disputeId: disputeRef.id,
            aggregateId: (fresh.aggregateId as string) ?? data.bookingId,
            bookingId: data.bookingId,
            sessionId: (fresh.sessionId as string | undefined) ?? null,
            reason: data.reason,
            openedByUserId: uid,
            openedByRole: actor,
            evidenceMetadata: data.evidenceMetadata,
          }),
        );

        tx.set(
          bookingRef,
          {
            disputeId: disputeRef.id,
            disputeStatus: "opened",
          },
          { merge: true },
        );

        appendAuditEvent(tx, db, {
          aggregateId: fresh.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          sessionId: fresh.sessionId ?? null,
          disputeId: disputeRef.id,
          actorId: uid,
          actorRole: actor,
          action: "open_dispute",
          previousStatus: currentStatus ?? null,
          newStatus: guard.to,
          reason: data.reason,
          source: actor === "admin" ? "adminPanel" : "mobileApp",
        });

        return {
          bookingId: data.bookingId,
          disputeId: disputeRef.id,
          lifecycleStatus: guard.to,
        };
      },
    );

    if (!replayed) {
      const studentId = participants.studentId;
      const teacherId = participants.teacherId;
      const sessionId = (booking.sessionId as string | undefined) ?? "";
      if (studentId && teacherId && sessionId) {
        await enqueueSessionNotification(db, {
          sessionId,
          aggregateId: (booking.aggregateId as string) ?? data.bookingId,
          kind: "disputeOpened",
          recipientUserIds: [studentId, teacherId],
          payload: { reason: data.reason },
        });
      }
    }

    return result;
  },
);

interface ResolveSessionDisputeRequest {
  bookingId: string;
  disputeId: string;
  resolution:
    | "favor_student"
    | "favor_teacher"
    | "with_compensation"
    | "rejected"
    | "closed";
  reason: string;
  idempotencyKey?: string;
}

export const resolveSessionDispute = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const data = request.data as ResolveSessionDisputeRequest;
    if (
      !data.bookingId ||
      !data.disputeId ||
      !data.resolution ||
      !data.reason?.trim()
    ) {
      throw new HttpsError(
        "invalid-argument",
        "bookingId, disputeId, resolution, and reason required.",
      );
    }

    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const disputeRef = db.collection("quran_session_disputes").doc(data.disputeId);

    const uid = requireAdmin(request);

    const operationKey = buildOperationKey(
      "resolve_dispute",
      `${data.bookingId}:${data.disputeId}`,
      data.idempotencyKey,
    );

    return runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: uid,
        action: "resolve_dispute",
      },
      async (tx) => {
        const [bookingSnap, disputeSnap] = await Promise.all([
          tx.get(bookingRef),
          tx.get(disputeRef),
        ]);
        if (!bookingSnap.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }
        if (!disputeSnap.exists) {
          throw new HttpsError("not-found", "Dispute not found.");
        }

        const booking = bookingSnap.data() ?? {};
        const currentStatus = booking.lifecycleStatus as LifecycleStatus | undefined;
        if (currentStatus !== "disputed") {
          throw lifecycleError("invalid_transition", "Booking is not disputed.", {
            currentStatus: currentStatus ?? null,
            action: "resolve_dispute",
          });
        }

        const sessionRef = sessionRefForBooking(db, booking);
        const disputeStatus = disputeStatusForResolution(data.resolution);
        let nextLifecycle: LifecycleStatus = "disputed";

        if (data.resolution === "with_compensation") {
          const guard = validateTransition({
            currentStatus,
            action: "issue_compensation",
            actor: "admin",
            reason: data.reason,
          });
          nextLifecycle = guard.to;
        } else if (data.resolution === "favor_student") {
          const guard = validateTransition({
            currentStatus,
            action: "issue_refund",
            actor: "admin",
            reason: data.reason,
          });
          nextLifecycle = guard.to;
        }

        if (nextLifecycle !== "disputed") {
          writeAggregateLifecycle(tx, { bookingRef, sessionRef }, nextLifecycle);
        }

        tx.set(
          disputeRef,
          {
            status: disputeStatus,
            resolutionReason: data.reason,
            resolvedByUserId: uid,
            resolvedAt: new Date(),
            updatedAt: new Date(),
          },
          { merge: true },
        );

        tx.set(
          bookingRef,
          { disputeStatus, updatedAt: new Date() },
          { merge: true },
        );

        appendAuditEvent(tx, db, {
          aggregateId: booking.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          sessionId: booking.sessionId ?? null,
          disputeId: data.disputeId,
          actorId: uid,
          actorRole: "admin",
          action: "resolve_dispute",
          previousStatus: currentStatus,
          newStatus: nextLifecycle,
          reason: data.reason,
          resolution: data.resolution,
          source: "adminPanel",
        });

        return {
          bookingId: data.bookingId,
          disputeId: data.disputeId,
          disputeStatus,
          lifecycleStatus: nextLifecycle,
        };
      },
    ).then(({ result }) => result);
  },
);
