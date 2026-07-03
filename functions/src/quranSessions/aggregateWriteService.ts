import {
  Firestore,
  Timestamp,
  Transaction,
  FieldValue,
} from "firebase-admin/firestore";

import { buildAllowedActionsDenorm } from "./sessionAllowedActionsService";
import {
  legacyStatusForLifecycle,
  type LifecycleStatus,
} from "./sessionLifecycleService";

function parseFirestoreDate(raw: unknown): Date | null {
  if (raw instanceof Timestamp) {
    return raw.toDate();
  }
  if (typeof raw === "string") {
    const parsed = new Date(raw);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

/** Recomputes Q-SR-02 denorm fields from aggregate timing + lifecycle status. */
export function allowedActionsPatchFromAggregate(
  lifecycleStatus: LifecycleStatus | string,
  source: Record<string, unknown>,
): Record<string, unknown> {
  const startsAt = parseFirestoreDate(source.startsAt);
  const endsAt = parseFirestoreDate(source.endsAt);
  if (startsAt == null || endsAt == null) {
    return {};
  }
  const joinWindowLeadMs =
    typeof source.joinWindowLeadMs === "number"
      ? source.joinWindowLeadMs
      : undefined;
  return buildAllowedActionsDenorm({
    studentId: (source.studentId as string | undefined) ?? "",
    teacherUserId: (source.teacherUserId as string | undefined) ?? "",
    lifecycleStatus,
    startsAt,
    endsAt,
    joinWindowLeadMs,
  });
}

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
  timingSource?: Record<string, unknown>,
): void {
  const now = FieldValue.serverTimestamp();
  const allowedPatch = timingSource
    ? allowedActionsPatchFromAggregate(lifecycleStatus, {
        ...timingSource,
        ...extraBooking,
        ...extraSession,
      })
    : {};
  tx.set(
    refs.bookingRef,
    {
      lifecycleStatus,
      status: legacyStatusForLifecycle(lifecycleStatus),
      updatedAt: now,
      ...allowedPatch,
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
        ...allowedPatch,
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
