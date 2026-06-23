import test from "node:test";
import assert from "node:assert/strict";
import type { Firestore, Transaction } from "firebase-admin/firestore";

import {
  postWalletCreditInTransaction,
  refundWalletIdempotencyKey,
  walletIdForUser,
} from "../../src/quranSessions/walletService";

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
    const data = this.staged.has(ref.path)
      ? this.staged.get(ref.path)
      : this.store.get(ref.path);
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

  update(ref: FakeDocRef, data: Record<string, unknown>) {
    this.hasWritten = true;
    const base = this.staged.get(ref.path) ?? this.store.get(ref.path) ?? {};
    this.staged.set(ref.path, { ...base, ...data });
  }
}

class FakeFirestore {
  readonly store = new Map<string, DocData>();

  collection(name: string) {
    return {
      doc: (id: string) => new FakeDocRef(`${name}/${id}`),
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
}

function asFirestore(fake: FakeFirestore): Firestore {
  return fake as unknown as Firestore;
}

test("postWalletCreditInTransaction creates wallet and posted transaction", async () => {
  const fake = new FakeFirestore();
  const db = asFirestore(fake);

  const result = await fake.runTransaction(async (tx) =>
    postWalletCreditInTransaction({
      tx: tx as unknown as Transaction,
      db,
      userId: "student1",
      amount: 120,
      idempotencyKey: refundWalletIdempotencyKey("refund_1"),
      type: "refund_credit",
      sourceType: "refund",
      sourceId: "refund_1",
      description: "Session refund",
      actorId: "system",
      actorRole: "system",
    }),
  );

  assert.equal(result.replayed, false);
  assert.equal(result.balanceAfter, 120);
  const wallet = fake.store.get(`user_wallets/${walletIdForUser("student1")}`);
  assert.equal(wallet?.availableBalance, 120);
  assert.equal(wallet?.currency, "EGP");
});

test("postWalletCreditInTransaction is idempotent on duplicate key", async () => {
  const fake = new FakeFirestore();
  const db = asFirestore(fake);
  const idempotencyKey = refundWalletIdempotencyKey("refund_dup");

  const first = await fake.runTransaction(async (tx) =>
    postWalletCreditInTransaction({
      tx: tx as unknown as Transaction,
      db,
      userId: "student1",
      amount: 50,
      idempotencyKey,
      type: "refund_credit",
      sourceType: "refund",
      sourceId: "refund_dup",
      description: "Refund",
      actorId: "system",
      actorRole: "system",
    }),
  );

  const second = await fake.runTransaction(async (tx) =>
    postWalletCreditInTransaction({
      tx: tx as unknown as Transaction,
      db,
      userId: "student1",
      amount: 50,
      idempotencyKey,
      type: "refund_credit",
      sourceType: "refund",
      sourceId: "refund_dup",
      description: "Refund",
      actorId: "system",
      actorRole: "system",
    }),
  );

  assert.equal(first.replayed, false);
  assert.equal(second.replayed, true);
  assert.equal(first.transactionId, second.transactionId);
  const wallet = fake.store.get(`user_wallets/${walletIdForUser("student1")}`);
  assert.equal(wallet?.availableBalance, 50);
});

test("postWalletCreditInTransaction increments balance on second unique credit", async () => {
  const fake = new FakeFirestore();
  const db = asFirestore(fake);

  await fake.runTransaction(async (tx) =>
    postWalletCreditInTransaction({
      tx: tx as unknown as Transaction,
      db,
      userId: "student1",
      amount: 30,
      idempotencyKey: refundWalletIdempotencyKey("refund_a"),
      type: "refund_credit",
      sourceType: "refund",
      sourceId: "refund_a",
      description: "Refund A",
      actorId: "system",
      actorRole: "system",
    }),
  );

  const second = await fake.runTransaction(async (tx) =>
    postWalletCreditInTransaction({
      tx: tx as unknown as Transaction,
      db,
      userId: "student1",
      amount: 70,
      idempotencyKey: refundWalletIdempotencyKey("refund_b"),
      type: "refund_credit",
      sourceType: "refund",
      sourceId: "refund_b",
      description: "Refund B",
      actorId: "system",
      actorRole: "system",
    }),
  );

  assert.equal(second.balanceAfter, 100);
  const wallet = fake.store.get(`user_wallets/${walletIdForUser("student1")}`);
  assert.equal(wallet?.availableBalance, 100);
});

test("postWalletCreditInTransaction reads wallet before writes", async () => {
  const fake = new FakeFirestore();
  const db = asFirestore(fake);
  fake.store.set(`user_wallets/${walletIdForUser("student1")}`, {
    walletId: walletIdForUser("student1"),
    userId: "student1",
    availableBalance: 10,
    heldBalance: 0,
    version: 1,
    currency: "EGP",
    status: "active",
  });

  await assert.doesNotReject(async () => {
    await fake.runTransaction(async (tx) =>
      postWalletCreditInTransaction({
        tx: tx as unknown as Transaction,
        db,
        userId: "student1",
        amount: 5,
        idempotencyKey: refundWalletIdempotencyKey("refund_order"),
        type: "refund_credit",
        sourceType: "refund",
        sourceId: "refund_order",
        description: "Refund",
        actorId: "system",
        actorRole: "system",
      }),
    );
  });
});
