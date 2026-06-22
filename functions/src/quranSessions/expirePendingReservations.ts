import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const expirePendingReservations = onSchedule(
  "every 5 minutes",
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const pending = await db
      .collection("quran_bookings")
      .where("lifecycleStatus", "==", "pending_payment")
      .where("startsAt", "<=", Timestamp.fromMillis(Date.now() + 10 * 60 * 1000))
      .get();

    const batch = db.batch();
    for (const doc of pending.docs) {
      const data = doc.data();
      const slotId = data.slotId as string | undefined;
      batch.set(
        doc.ref,
        { lifecycleStatus: "expired", status: "rejected", updatedAt: now },
        { merge: true },
      );
      if (slotId) {
        batch.delete(db.collection("quran_slot_locks").doc(slotId));
      }
      batch.set(db.collection("quran_session_events").doc(), {
        aggregateId: data.aggregateId ?? doc.id,
        bookingId: doc.id,
        sessionId: data.sessionId ?? null,
        actorId: "system",
        actorRole: "system",
        action: "expire_pending_reservation",
        previousStatus: data.lifecycleStatus ?? null,
        newStatus: "expired",
        source: "backendJob",
        timestamp: now,
      });
    }
    if (!pending.empty) {
      await batch.commit();
    }
  },
);
