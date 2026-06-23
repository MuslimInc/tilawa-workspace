import test from "node:test";
import assert from "node:assert/strict";
import type { Firestore, Transaction } from "firebase-admin/firestore";

import {
  PAYMENT_INTENTS_COLLECTION,
  SandboxPaymentProvider,
} from "../../src/quranSessions/payment/sandboxPaymentProvider";
import { confirmBookingPayment } from "../../src/quranSessions/confirmBookingPayment";
import { createSessionBooking } from "../../src/quranSessions/createSessionBooking";

class ReadAfterWriteError extends Error {
  constructor() {
    super(
      "Firestore transactions require all reads to be executed before all writes.",
    );
  }
}

type DocData = Record<string, unknown> | undefined;

class FakeDocRef {
  constructor(
    public readonly path: string,
    private readonly store: Map<string, DocData>,
  ) {}

  async get() {
    const data = this.store.get(this.path);
    return { exists: data !== undefined, data: () => data };
  }
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
    return { exists: data !== undefined, data: () => data, ref };
  }

  set(
    ref: FakeDocRef,
    data: Record<string, unknown>,
    options?: { merge?: boolean },
  ) {
    this.hasWritten = true;
    if (options?.merge) {
      const base = this.staged.get(ref.path) ?? this.store.get(ref.path) ?? {};
      this.staged.set(ref.path, { ...base, ...data });
    } else {
      this.staged.set(ref.path, data);
    }
  }

  update(ref: FakeDocRef, data: Record<string, unknown>) {
    this.set(ref, data, { merge: true });
  }

  delete(ref: FakeDocRef) {
    this.hasWritten = true;
    this.staged.set(ref.path, undefined);
  }
}

class FakeFirestore {
  readonly store = new Map<string, DocData>();

  collection(name: string) {
    const store = this.store;
    return {
      doc: (id: string) => new FakeDocRef(`${name}/${id}`, store),
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

function asTransaction(tx: FakeTransaction): Transaction {
  return tx as unknown as Transaction;
}

test("sandbox provider creates payment intent in transaction", async () => {
  const fake = new FakeFirestore();
  const provider = new SandboxPaymentProvider();
  const db = asFirestore(fake);

  await db.runTransaction(async (rawTx) => {
    const tx = rawTx as unknown as FakeTransaction;
    const result = await provider.createPaymentIntent({
      db,
      tx: asTransaction(tx),
      bookingId: "booking_1",
      aggregateId: "booking_1",
      studentId: "student_1",
      amount: 100,
      currency: "EGP",
      platformFee: 0,
      teacherAmount: 100,
      tax: 0,
      idempotencyKey: "idem_1",
      expiresAt: new Date("2099-01-01T00:00:00.000Z"),
    });
    assert.equal(result.paymentReference, "sandbox_ref_booking_1");
    assert.match(result.clientConfirmToken, /^sandbox_confirm_booking_1_/);
  });

  const intentPath = `${PAYMENT_INTENTS_COLLECTION}/sandbox_pi_booking_1`;
  const intent = fake.store.get(intentPath);
  assert.ok(intent);
  assert.equal(intent?.status, "requires_confirmation");
  assert.equal(intent?.amount, 100);
});

test("sandbox confirm precheck rejects invalid token", async () => {
  const fake = new FakeFirestore();
  const provider = new SandboxPaymentProvider();
  const db = asFirestore(fake);

  await db.runTransaction(async (rawTx) => {
    const tx = rawTx as unknown as FakeTransaction;
    await provider.createPaymentIntent({
      db,
      tx: asTransaction(tx),
      bookingId: "booking_2",
      aggregateId: "booking_2",
      studentId: "student_1",
      amount: 50,
      currency: "EGP",
      platformFee: 0,
      teacherAmount: 50,
      tax: 0,
      idempotencyKey: "idem_2",
      expiresAt: new Date("2099-01-01T00:00:00.000Z"),
    });
  });

  await assert.rejects(
    () =>
      provider.confirmPayment({
        db,
        paymentReference: "sandbox_ref_booking_2",
        clientConfirmToken: "wrong_token",
        bookingId: "booking_2",
        studentId: "student_1",
      }),
    /invalid_confirm_token/,
  );
});

test("sandbox confirm precheck is idempotent when intent already succeeded", async () => {
  const fake = new FakeFirestore();
  const provider = new SandboxPaymentProvider();
  const db = asFirestore(fake);
  const intentPath = `${PAYMENT_INTENTS_COLLECTION}/sandbox_pi_booking_3`;
  fake.store.set(intentPath, {
    paymentReference: "sandbox_ref_booking_3",
    clientConfirmToken: "token_3",
    studentId: "student_1",
    bookingId: "booking_3",
    status: "succeeded",
  });
  fake.store.set("quran_bookings/booking_3", {
    sessionId: "session_3",
    lifecycleStatus: "scheduled",
  });

  const result = await provider.confirmPayment({
    db,
    paymentReference: "sandbox_ref_booking_3",
    clientConfirmToken: "token_3",
    bookingId: "booking_3",
    studentId: "student_1",
  });

  assert.equal(result.alreadyConfirmed, true);
  assert.equal(result.lifecycleStatus, "scheduled");
});

test("createSessionBooking and confirmBookingPayment export as callables", () => {
  assert.equal(typeof createSessionBooking, "function");
  assert.equal(typeof confirmBookingPayment, "function");
});
