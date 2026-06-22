import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { nowServer } from "./sessionLifecycleService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { recordTerminalTransition } from "./metricsAggregationService";

interface MarkSessionNoShowRequest {
  sessionId: string;
  classification: "teacher_no_show" | "student_no_show" | "both_no_show";
}

export const markSessionNoShow = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const data = request.data as MarkSessionNoShowRequest;
    if (!data.sessionId || !data.classification) {
      throw new HttpsError("invalid-argument", "sessionId and classification required.");
    }
    const db = getFirestore();
    const now = nowServer();
    const sessionRef = db.collection("quran_sessions").doc(data.sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) throw new HttpsError("not-found", "Session not found.");
    const session = sessionSnap.data() ?? {};
    const bookingId = session.bookingId as string;
    await db.runTransaction(async (tx) => {
      tx.set(sessionRef, { lifecycleStatus: data.classification, updatedAt: now }, { merge: true });
      tx.set(
        db.collection("quran_bookings").doc(bookingId),
        { lifecycleStatus: data.classification, updatedAt: now },
        { merge: true },
      );
      tx.set(db.collection("quran_session_events").doc(), {
        aggregateId: session.aggregateId ?? bookingId,
        bookingId,
        sessionId: data.sessionId,
        actorId: request.auth?.uid,
        actorRole: "admin",
        action: "mark_no_show",
        previousStatus: session.lifecycleStatus ?? null,
        newStatus: data.classification,
        source: "adminPanel",
        timestamp: now,
      });
    });

    const teacherId = session.teacherId as string | undefined;
    const studentId = session.studentId as string | undefined;
    if (teacherId && studentId) {
      const metricsType =
        data.classification === "teacher_no_show"
          ? ({ type: "teacher_no_show", teacherId } as const)
          : data.classification === "student_no_show"
            ? ({ type: "student_no_show", studentId } as const)
            : ({ type: "both_no_show", teacherId, studentId } as const);
      await recordTerminalTransition(db, metricsType);
      await enqueueSessionNotification(db, {
        sessionId: data.sessionId,
        aggregateId: (session.aggregateId as string | undefined) ?? bookingId,
        kind: "noShowMarked",
        recipientUserIds: [teacherId, studentId],
        payload: { classification: data.classification },
      });
    }

    return { sessionId: data.sessionId, lifecycleStatus: data.classification };
  },
);
