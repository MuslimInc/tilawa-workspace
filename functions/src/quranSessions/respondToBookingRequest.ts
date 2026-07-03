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
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import {
  resolveTeacherProfileUserId,
  teacherUserIdFromDenormalizedSessionData,
} from "./teacherProfileUserId";
import {
  requireAuthenticatedUid,
  requireValidSessionEpoch,
  resolveActorRole,
} from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

type BookingResponse = "accept" | "reject";

interface RespondToBookingRequestInput {
  bookingId: string;
  response: BookingResponse;
  reason?: string;
  idempotencyKey?: string;
}

export const respondToBookingRequest = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpoch(request, uid);
    const data = request.data as RespondToBookingRequestInput;
    if (!data.bookingId?.trim()) {
      throw new HttpsError("invalid-argument", "bookingId required.");
    }
    if (data.response !== "accept" && data.response !== "reject") {
      throw new HttpsError("invalid-argument", "response must be accept|reject.");
    }

    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }
    const booking = bookingSnap.data() ?? {};
    const teacherProfileId = (booking.teacherId as string) ?? "";
    const studentId = (booking.studentId as string) ?? "";
    const teacherUserId =
      teacherUserIdFromDenormalizedSessionData(booking) ??
      (await resolveTeacherProfileUserId(db, teacherProfileId));

    const actor = resolveActorRole(
      request,
      "teacher",
      { studentId, teacherId: teacherProfileId },
      teacherUserId,
    );
    if (actor !== "teacher") {
      throw new HttpsError(
        "permission-denied",
        "Only the assigned teacher may respond.",
      );
    }

    const action =
      data.response === "accept"
        ? "accept_booking_request"
        : "reject_booking_request";
    const operationKey = buildOperationKey(
      action,
      data.bookingId,
      data.idempotencyKey ?? data.response,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: uid,
        action,
      },
      async (tx) => {
        const freshSnap = await tx.get(bookingRef);
        if (!freshSnap.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }
        const fresh = freshSnap.data() ?? {};
        const currentStatus = fresh.lifecycleStatus as
          | LifecycleStatus
          | undefined;

        if (currentStatus === "scheduled" && data.response === "accept") {
          return {
            bookingId: data.bookingId,
            lifecycleStatus: "scheduled" as LifecycleStatus,
            sessionId: (fresh.sessionId as string | undefined) ?? "",
            studentId,
            skipped: true,
          };
        }
        if (
          currentStatus === "rejected_by_tutor" &&
          data.response === "reject"
        ) {
          return {
            bookingId: data.bookingId,
            lifecycleStatus: "rejected_by_tutor" as LifecycleStatus,
            sessionId: (fresh.sessionId as string | undefined) ?? "",
            studentId,
            skipped: true,
          };
        }

        const guard = validateTransition({
          currentStatus: currentStatus ?? null,
          action,
          actor: "teacher",
          reason: data.reason,
        });

        const sessionRef = sessionRefForBooking(db, fresh);
        const now = Timestamp.now();
        const lifecyclePatch: Record<string, unknown> = {};
        if (data.response === "accept") {
          lifecyclePatch.acceptedAt = now;
          lifecyclePatch.acceptedByTeacherUserId = uid;
        } else {
          lifecyclePatch.rejectedAt = now;
          lifecyclePatch.rejectedByTeacherUserId = uid;
          if (data.reason?.trim()) {
            lifecyclePatch.rejectionReason = data.reason.trim();
          }
        }

        writeAggregateLifecycle(
          tx,
          { bookingRef, sessionRef },
          guard.to,
          lifecyclePatch,
          {},
          fresh,
        );

        const slotId = fresh.slotId as string | undefined;
        if (slotId && guard.to === "rejected_by_tutor") {
          tx.delete(db.collection("quran_slot_locks").doc(slotId));
        }

        appendAuditEvent(tx, db, {
          aggregateId: fresh.aggregateId ?? data.bookingId,
          bookingId: data.bookingId,
          sessionId: fresh.sessionId ?? null,
          actorId: uid,
          actorRole: "teacher",
          action,
          previousStatus: currentStatus ?? null,
          newStatus: guard.to,
          reason: data.reason ?? null,
          source: "mobileApp",
        });

        return {
          bookingId: data.bookingId,
          lifecycleStatus: guard.to,
          sessionId: (fresh.sessionId as string | undefined) ?? "",
          studentId,
          skipped: false,
        };
      },
    );

    if (!replayed && !result.skipped && result.sessionId) {
      if (result.lifecycleStatus === "scheduled") {
        await recordTerminalTransition(db, {
          type: "booking_confirmed",
          teacherId: teacherUserId,
          studentId: result.studentId,
        });
        await enqueueSessionNotification(db, {
          sessionId: result.sessionId,
          aggregateId: data.bookingId,
          kind: "bookingRequestAccepted",
          recipientUserIds: [result.studentId],
        });
      } else if (result.lifecycleStatus === "rejected_by_tutor") {
        await enqueueSessionNotification(db, {
          sessionId: result.sessionId,
          aggregateId: data.bookingId,
          kind: "bookingRequestRejected",
          recipientUserIds: [result.studentId],
          payload: { reason: data.reason ?? "" },
        });
      }
    }

    return {
      bookingId: result.bookingId,
      lifecycleStatus: result.lifecycleStatus,
    };
  },
);
