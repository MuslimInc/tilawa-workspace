import {
  Firestore,
  Transaction,
  DocumentReference,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";

import { BOOKING_IDEMPOTENCY_DEDUPE_MS } from "./platformSchedulingPolicy";

const COLLECTION = "quran_session_operations";

export interface IdempotentOperationInput {
  db: Firestore;
  operationKey: string;
  actorId: string;
  action: string;
  /** When set, completed markers older than this window are ignored (Q-BK-04). */
  dedupeWindowMs?: number;
}

export interface IdempotentOperationResult<T> {
  replayed: boolean;
  result: T;
}

export function buildOperationKey(
  action: string,
  entityId: string,
  idempotencyKey?: string,
): string {
  const suffix = idempotencyKey?.trim() || "default";
  return `${action}:${entityId}:${suffix}`;
}

export async function runIdempotentOperation<T>(
  input: IdempotentOperationInput,
  execute: (tx: Transaction) => Promise<T>,
): Promise<IdempotentOperationResult<T>> {
  const ref = input.db.collection(COLLECTION).doc(input.operationKey);

  return input.db.runTransaction(async (tx) => {
    // READ PHASE. The operation marker is read first. Crucially, we do NOT
    // write a "pending" marker here: the business reads performed inside
    // `execute` (which itself reads before it writes) would then run *after* a
    // write, and Firestore aborts any transaction that reads after a write
    // ("all reads must precede all writes"). Deferring the marker write to the
    // end keeps the whole transaction read-before-write correct.
    const existing = await tx.get(ref);
    if (existing.exists) {
      const data = existing.data() ?? {};
      const dedupeWindowMs =
        input.dedupeWindowMs ?? BOOKING_IDEMPOTENCY_DEDUPE_MS;
      const completedAtRaw = data.completedAt;
      let completedAtMs: number | null = null;
      if (completedAtRaw instanceof Timestamp) {
        completedAtMs = completedAtRaw.toMillis();
      } else if (
        completedAtRaw &&
        typeof (completedAtRaw as { toMillis?: unknown }).toMillis === "function"
      ) {
        completedAtMs = (completedAtRaw as { toMillis(): number }).toMillis();
      } else if (completedAtRaw instanceof Date) {
        completedAtMs = completedAtRaw.getTime();
      }
      if (completedAtMs != null) {
        const ageMs = Date.now() - completedAtMs;
        if (ageMs <= dedupeWindowMs) {
          return { replayed: true, result: data.result as T };
        }
        // Outside dedupe window — allow a fresh operation with the same key.
      } else if (existing.exists) {
        return { replayed: true, result: data.result as T };
      }
    }

    // WRITE PHASE. `execute` performs its own reads-before-writes, then the
    // completion marker (carrying the result) is persisted in the same atomic
    // transaction. Concurrent calls with the same key contend on `ref`; the
    // loser retries, observes the completed marker, and replays.
    const result = await execute(tx);

    tx.set(ref, {
      operationKey: input.operationKey,
      action: input.action,
      actorId: input.actorId,
      status: "completed",
      result,
      createdAt: FieldValue.serverTimestamp(),
      completedAt: FieldValue.serverTimestamp(),
    });

    return { replayed: false, result };
  });
}

export function operationRef(
  db: Firestore,
  operationKey: string,
): DocumentReference {
  return db.collection(COLLECTION).doc(operationKey);
}
