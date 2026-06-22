import {
  Firestore,
  Transaction,
  DocumentReference,
  FieldValue,
} from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

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
    const existing = await tx.get(ref);
    if (existing.exists) {
      const data = existing.data() ?? {};
      if (data.status === "completed") {
        return {
          replayed: true,
          result: data.result as T,
        };
      }
      throw new HttpsError(
        "aborted",
        "Operation already in progress. Retry shortly.",
      );
    }

    tx.set(ref, {
      operationKey: input.operationKey,
      action: input.action,
      actorId: input.actorId,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    const result = await execute(tx);

    tx.set(
      ref,
      {
        status: "completed",
        result,
        completedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { replayed: false, result };
  });
}

export function operationRef(
  db: Firestore,
  operationKey: string,
): DocumentReference {
  return db.collection(COLLECTION).doc(operationKey);
}
