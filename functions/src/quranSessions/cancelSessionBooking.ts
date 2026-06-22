import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { legacyStatusForLifecycle, nowServer, LifecycleStatus } from "./sessionLifecycleService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { recordTerminalTransition } from "./metricsAggregationService";

interface CancelSessionBookingRequest {
  bookingId: string;
  reason: string;
  actorRole?: "student" | "teacher" | "admin" | "system";
}

function cancellationStatus(role: string): LifecycleStatus {
  switch (role) {
    case "teacher":
      return "cancelled_by_teacher";
    case "admin":
    case "system":
      return "cancelled_by_admin";
    default:
      return "cancelled_by_student";
  }
}

export const cancelSessionBooking = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const data = request.data as CancelSessionBookingRequest;
    if (!data.bookingId || !data.reason) {
      throw new HttpsError("invalid-argument", "bookingId and reason required.");
    }
    const role = data.actorRole ?? "student";
    if (role === "admin" && !request.auth.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    const db = getFirestore();
    const bookingRef = db.collection("quran_bookings").doc(data.bookingId);
    const now = nowServer();
    const lifecycleStatus = cancellationStatus(role);

    let teacherId = "";
    let studentId = "";
    let sessionId = "";

    await db.runTransaction(async (tx) => {
      const bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) {
        throw new HttpsError("not-found", "Booking not found.");
      }
      const booking = bookingSnap.data() ?? {};
      teacherId = (booking.teacherId as string | undefined) ?? "";
      studentId = (booking.studentId as string | undefined) ?? "";
      sessionId = (booking.sessionId as string | undefined) ?? "";
      tx.set(
        bookingRef,
        {
          lifecycleStatus,
          status: legacyStatusForLifecycle(lifecycleStatus),
          cancellationReason: data.reason,
          cancelledAt: now,
          cancelledByActorId: request.auth?.uid,
          cancelledByRole: role,
          updatedAt: now,
        },
        { merge: true },
      );

      if (sessionId) {
        tx.set(
          db.collection("quran_sessions").doc(sessionId),
          {
            lifecycleStatus,
            status:
              lifecycleStatus === "cancelled_by_student"
                ? "cancelled_by_student"
                : "cancelled_by_teacher",
            updatedAt: now,
          },
          { merge: true },
        );
      }
      const slotId = booking.slotId as string | undefined;
      if (slotId) {
        tx.delete(db.collection("quran_slot_locks").doc(slotId));
      }
      tx.set(db.collection("quran_session_events").doc(), {
        aggregateId: booking.aggregateId ?? data.bookingId,
        bookingId: data.bookingId,
        sessionId: booking.sessionId ?? null,
        actorId: request.auth?.uid ?? "system",
        actorRole: role,
        action: "cancel_session",
        previousStatus: booking.lifecycleStatus ?? null,
        newStatus: lifecycleStatus,
        reason: data.reason,
        source: role === "admin" ? "adminPanel" : "mobileApp",
        timestamp: now,
      });
    });

    if (teacherId && studentId && sessionId) {
      if (lifecycleStatus === "cancelled_by_teacher") {
        await recordTerminalTransition(db, {
          type: "cancelled_by_teacher",
          teacherId,
        });
      } else if (lifecycleStatus === "cancelled_by_student") {
        await recordTerminalTransition(db, {
          type: "cancelled_by_student",
          studentId,
        });
      }
      await enqueueSessionNotification(db, {
        sessionId,
        aggregateId: data.bookingId,
        kind: "cancellation",
        recipientUserIds: [teacherId, studentId],
        payload: { reason: data.reason, actorRole: role },
      });
    }

    return { bookingId: data.bookingId, lifecycleStatus };
  },
);
