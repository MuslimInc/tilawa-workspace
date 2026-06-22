import test from "node:test";
import assert from "node:assert/strict";
import type { DocumentReference, Firestore, Transaction } from "firebase-admin/firestore";

import { runIdempotentOperation } from "../../src/quranSessions/idempotencyService";

/**
 * Minimal in-memory Firestore double that reproduces the one invariant unit
 * fakes usually miss and that shipped the original bug: a transaction must
 * execute ALL reads before ANY write. The real Admin SDK throws exactly this
 * message if `get` is called after `set`/`delete`.
 */
class ReadAfterWriteError extends Error {
  constructor() {
    super(
      "Firestore transactions require all reads to be executed before all writes.",
    );
  }
}

type DocData = Record<string, unknown> | undefined;

class FakeDocRef {
  constructor(public readonly path: string) {}
}

class FakeTransaction {
  private hasWritten = false;

  constructor(
    private readonly store: Map<string, DocData>,
    private readonly staged: Map<string, DocData>,
  ) {}

  async get(ref: FakeDocRef) {
    if (this.hasWritten) {
      throw new ReadAfterWriteError();
    }
    const data = this.store.get(ref.path);
    return { exists: data !== undefined, data: () => data };
  }

  set(ref: FakeDocRef, data: Record<string, unknown>, options?: { merge?: boolean }) {
    this.hasWritten = true;
    if (options?.merge) {
      const base = this.staged.get(ref.path) ?? this.store.get(ref.path) ?? {};
      this.staged.set(ref.path, { ...base, ...data });
    } else {
      this.staged.set(ref.path, data);
    }
  }

  delete(ref: FakeDocRef) {
    this.hasWritten = true;
    this.staged.set(ref.path, undefined);
  }
}

class FakeFirestore {
  readonly store = new Map<string, DocData>();
  private autoId = 0;

  collection(name: string) {
    return {
      doc: (id?: string) =>
        new FakeDocRef(`${name}/${id ?? `auto_${this.autoId++}`}`),
    };
  }

  async runTransaction<T>(fn: (tx: FakeTransaction) => Promise<T>): Promise<T> {
    const staged = new Map<string, DocData>();
    const tx = new FakeTransaction(this.store, staged);
    const result = await fn(tx);
    for (const [path, data] of staged) {
      if (data === undefined) this.store.delete(path);
      else this.store.set(path, data);
    }
    return result;
  }

  seed(path: string, data: Record<string, unknown>) {
    this.store.set(path, data);
  }
}

function asFirestore(fake: FakeFirestore): Firestore {
  return fake as unknown as Firestore;
}

test("runIdempotentOperation reads booking before writing the marker (no read-after-write)", async () => {
  const fake = new FakeFirestore();
  fake.seed("quran_bookings/b1", { lifecycleStatus: "disputed" });
  const bookingRef = fake.collection("quran_bookings").doc("b1") as unknown as FakeDocRef;

  // `execute` mirrors a real money callable: it READS the booking, then WRITES.
  // Under the old (pending-marker-first) ordering this throws ReadAfterWriteError.
  const { replayed, result } = await runIdempotentOperation(
    { db: asFirestore(fake), operationKey: "issue_refund:b1:default", actorId: "admin1", action: "issue_refund" },
    async (tx: Transaction) => {
      const snap = await tx.get(bookingRef as unknown as DocumentReference);
      assert.equal(snap.exists, true);
      tx.set(bookingRef as unknown as DocumentReference, { lifecycleStatus: "refunded" }, { merge: true });
      return { lifecycleStatus: "refunded" as const };
    },
  );

  assert.equal(replayed, false);
  assert.equal(result.lifecycleStatus, "refunded");
  assert.equal(fake.store.get("quran_bookings/b1")?.lifecycleStatus, "refunded");
  assert.equal(fake.store.get("quran_session_operations/issue_refund:b1:default")?.status, "completed");
});

test("runIdempotentOperation replays without repeating side effects", async () => {
  const fake = new FakeFirestore();
  fake.seed("quran_bookings/b1", { lifecycleStatus: "disputed" });
  const bookingRef = fake.collection("quran_bookings").doc("b1") as unknown as FakeDocRef;
  let executeCount = 0;

  const run = () =>
    runIdempotentOperation(
      { db: asFirestore(fake), operationKey: "issue_refund:b1:default", actorId: "admin1", action: "issue_refund" },
      async (tx: Transaction) => {
        executeCount += 1;
        await tx.get(bookingRef as unknown as DocumentReference);
        tx.set(bookingRef as unknown as DocumentReference, { refundCount: executeCount }, { merge: true });
        return { refundId: `refund_${executeCount}` };
      },
    );

  const first = await run();
  const second = await run();

  assert.equal(first.replayed, false);
  assert.equal(second.replayed, true);
  assert.equal(executeCount, 1, "execute must run exactly once across duplicate calls");
  assert.equal(first.result.refundId, second.result.refundId);
  assert.equal(fake.store.get("quran_bookings/b1")?.refundCount, 1);
});
