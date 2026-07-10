import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { requireAuthenticatedUid, requireValidSessionEpochUnlessAdmin, resolveActorRole } from "./sessionAuth";
import { resolveTeacherProfileUserId, teacherUserIdFromDenormalizedSessionData } from "./teacherProfileUserId";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import { nowServer } from "./sessionLifecycleService";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

interface RequestSessionRescheduleRequest {
  bookingId: string;
  newSlotId: string;
  newStartsAt: string;
  reason: string;
  actorRole?: "student" | "teacher";
  idempotencyKey?: string;
}

export const requestSessionReschedule = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);
    const data = request.data as RequestSessionRescheduleRequest;
    if (!data.bookingId || !data.newSlotId || !data.reason?.trim()) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
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
    const teacherUserId =
      teacherUserIdFromDenormalizedSessionData(booking) ??
      (await resolveTeacherProfileUserId(db, participants.teacherId));
    const actor = resolveActorRole(
      request,
      data.actorRole,
      participants,
      teacherUserId,
    );

    const operationKey = buildOperationKey(
      "request_reschedule",
      data.bookingId,
      data.idempotencyKey ?? data.newSlotId,
    );
    const now = nowServer();
    const expiresAt = Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
    const requestRef = db.collection("quran_reschedule_requests").doc();

    const { result } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: request.auth!.uid,
        action: "request_reschedule",
      },
      async (tx) => {
        const freshSnap = await tx.get(bookingRef);
        const fresh = freshSnap.data() ?? {};
        const currentStatus = fresh.lifecycleStatus as LifecycleStatus | undefined;

        const guard = validateTransition({
          currentStatus: currentStatus ?? null,
          action: "request_reschedule",
          actor,
          reason: data.reason,
        });

        const sessionRef = sessionRefForBooking(db, fresh);
        writeAggregateLifecycle(tx, { bookingRef, sessionRef }, guard.to, {}, {}, fresh);

        tx.set(requestRef, {
          requestId: requestRef.id,
          aggregateId: fresh.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          requestedByUserId: request.auth?.uid,
          requestedByRole: actor,
          reason: data.reason,
          oldSlotId: fresh.slotId,
          newSlotId: data.newSlotId,
          newStartsAt: Timestamp.fromDate(new Date(data.newStartsAt)),
          status: "pending",
          createdAt: now,
          expiresAt,
        });

        appendAuditEvent(tx, db, {
          aggregateId: fresh.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          sessionId: fresh.sessionId ?? null,
          actorId: request.auth?.uid,
          actorRole: actor,
          action: "request_reschedule",
          previousStatus: currentStatus ?? null,
          newStatus: guard.to,
          reason: data.reason,
          source: "mobileApp",
        });

        return {
          bookingId: data.bookingId,
          requestId: requestRef.id,
          status: "pending",
        };
      },
    );

    return result;
  },
);
