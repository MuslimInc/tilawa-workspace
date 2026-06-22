import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { nowServer } from "./sessionLifecycleService";
import { recordTerminalTransition } from "./metricsAggregationService";

interface CompleteSessionRequest {
  sessionId: string;
}

export const completeSession = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const data = request.data as CompleteSessionRequest;
    if (!data.sessionId) throw new HttpsError("invalid-argument", "sessionId required.");

    const db = getFirestore();
    const sessionRef = db.collection("quran_sessions").doc(data.sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) throw new HttpsError("not-found", "Session not found.");
    const session = sessionSnap.data() ?? {};
    const bookingId = session.bookingId as string;
    const now = nowServer();

    await db.runTransaction(async (tx) => {
      tx.set(
        sessionRef,
        { lifecycleStatus: "completed", status: "completed", completedAt: now, updatedAt: now },
        { merge: true },
      );
      tx.set(
        db.collection("quran_bookings").doc(bookingId),
        { lifecycleStatus: "completed", status: "completed", updatedAt: now },
        { merge: true },
      );
      tx.set(db.collection("quran_session_events").doc(), {
        aggregateId: session.aggregateId ?? bookingId,
        bookingId,
        sessionId: data.sessionId,
        actorId: request.auth?.uid,
        actorRole: "system",
        action: "complete_session",
        previousStatus: session.lifecycleStatus ?? null,
        newStatus: "completed",
        source: "backendJob",
        timestamp: now,
      });
    });

    const teacherId = session.teacherId as string | undefined;
    const studentId = session.studentId as string | undefined;
    if (teacherId && studentId) {
      await recordTerminalTransition(db, {
        type: "completed",
        teacherId,
        studentId,
      });
    }

    return { sessionId: data.sessionId, lifecycleStatus: "completed" };
  },
);
