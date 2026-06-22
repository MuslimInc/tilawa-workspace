import {
  Firestore,
  Transaction,
  FieldValue,
} from "firebase-admin/firestore";

import {
  legacyStatusForLifecycle,
  type LifecycleStatus,
} from "./sessionLifecycleService";

export interface AggregateRefs {
  bookingRef: FirebaseFirestore.DocumentReference;
  sessionRef?: FirebaseFirestore.DocumentReference;
}

export function writeAggregateLifecycle(
  tx: Transaction,
  refs: AggregateRefs,
  lifecycleStatus: LifecycleStatus,
  extraBooking: Record<string, unknown> = {},
  extraSession: Record<string, unknown> = {},
): void {
  const now = FieldValue.serverTimestamp();
  tx.set(
    refs.bookingRef,
    {
      lifecycleStatus,
      status: legacyStatusForLifecycle(lifecycleStatus),
      updatedAt: now,
      ...extraBooking,
    },
    { merge: true },
  );

  if (refs.sessionRef) {
    tx.set(
      refs.sessionRef,
      {
        lifecycleStatus,
        status: legacyStatusForLifecycle(lifecycleStatus),
        updatedAt: now,
        ...extraSession,
      },
      { merge: true },
    );
  }
}

export function sessionRefForBooking(
  db: Firestore,
  booking: Record<string, unknown>,
): FirebaseFirestore.DocumentReference | undefined {
  const sessionId = booking.sessionId as string | undefined;
  if (!sessionId) {
    return undefined;
  }
  return db.collection("quran_sessions").doc(sessionId);
}

export function appendAuditEvent(
  tx: Transaction,
  db: Firestore,
  event: Record<string, unknown>,
): void {
  tx.set(db.collection("quran_session_events").doc(), {
    timestamp: FieldValue.serverTimestamp(),
    ...event,
  });
}
