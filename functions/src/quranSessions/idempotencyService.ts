import {
  Firestore,
  Transaction,
  DocumentReference,
  FieldValue,
} from "firebase-admin/firestore";

const COLLECTION = "quran_session_operations";

export interface IdempotentOperationInput {
  db: Firestore;
  operationKey: string;
  actorId: string;
  action: string;
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
      // A committed marker only ever exists in the "completed" state because it
      // is written atomically with the business writes below — there is no
      // observable "pending" state. Treat any existing marker as a replay and
      // return the stored result without repeating side effects.
      const data = existing.data() ?? {};
      return { replayed: true, result: data.result as T };
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
