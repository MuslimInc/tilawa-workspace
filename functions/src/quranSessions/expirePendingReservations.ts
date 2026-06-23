import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import { buildOperationKey, runIdempotentOperation } from "./idempotencyService";
import { validateTransition } from "./sessionLifecycleGuard";

export const expirePendingReservations = onSchedule(
  "every 5 minutes",
  async () => {
    const db = getFirestore();
    const pending = await db
      .collection("quran_bookings")
      .where("lifecycleStatus", "==", "pending_payment")
      .where("startsAt", "<=", Timestamp.fromMillis(Date.now() + 10 * 60 * 1000))
      .get();

    for (const doc of pending.docs) {
      const operationKey = buildOperationKey(
        "expire_reservation",
        doc.id,
        "scheduler",
      );

      try {
        await runIdempotentOperation(
          {
            db,
            operationKey,
            actorId: "system",
            action: "expire_reservation",
          },
          async (tx) => {
            const fresh = await tx.get(doc.ref);
            if (!fresh.exists) {
              return { bookingId: doc.id, skipped: true };
            }
            const booking = fresh.data() ?? {};
            const currentStatus = booking.lifecycleStatus as string | undefined;
            if (currentStatus !== "pending_payment" && currentStatus !== "draft") {
              return { bookingId: doc.id, skipped: true };
            }

            const guard = validateTransition({
              currentStatus: currentStatus as "pending_payment" | "draft",
              action: "expire_reservation",
              actor: "system",
            });

            const sessionRef = sessionRefForBooking(db, booking);
            writeAggregateLifecycle(tx, { bookingRef: doc.ref, sessionRef }, guard.to);

            const slotId = booking.slotId as string | undefined;
            if (slotId) {
              tx.delete(db.collection("quran_slot_locks").doc(slotId));
            }

            appendAuditEvent(tx, db, {
              aggregateId: booking.aggregateId ?? doc.id,
              bookingId: doc.id,
              sessionId: booking.sessionId ?? null,
              actorId: "system",
              actorRole: "system",
              action: "expire_pending_reservation",
              previousStatus: currentStatus ?? null,
              newStatus: guard.to,
              source: "backendJob",
            });

            return { bookingId: doc.id, lifecycleStatus: guard.to };
          },
        );
      } catch (error) {
        console.error(`Failed to expire booking ${doc.id}:`, error);
      }
    }

    if (!pending.empty) {
      console.log(`Processed ${pending.docs.length} pending reservation(s).`);
    }
  },
);
