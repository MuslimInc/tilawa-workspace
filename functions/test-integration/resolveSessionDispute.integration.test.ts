import test from "node:test";
import assert from "node:assert/strict";

import {
  openSessionDispute,
  resolveSessionDispute,
} from "../src/quranSessions/sessionDisputeCallables";
import { clearFirestore, db } from "./support/emulator";

interface CallableLike<T> {
  run(req: {
    data: unknown;
    auth?: { uid: string; token?: Record<string, unknown> };
  }): Promise<T>;
}

const openDispute = openSessionDispute as unknown as CallableLike<{
  bookingId: string;
  disputeId: string;
  lifecycleStatus: string;
}>;

const resolveDispute = resolveSessionDispute as unknown as CallableLike<{
  bookingId: string;
  disputeId: string;
  lifecycleStatus: string;
  refundId: string | null;
  refundExecutionStatus: string | null;
  compensationId: string | null;
  compensationExecutionStatus: string | null;
}>;

async function seedDisputedBooking(): Promise<string> {
  await db().collection("quran_bookings").doc("booking1").set({
    bookingId: "booking1",
    aggregateId: "booking1",
    sessionId: "session1",
    studentId: "student1",
    teacherId: "teacher1",
    lifecycleStatus: "completed",
    amountPaidUsd: 25,
  });
  await db().collection("quran_sessions").doc("session1").set({
    sessionId: "session1",
    bookingId: "booking1",
    aggregateId: "booking1",
    studentId: "student1",
    teacherId: "teacher1",
    lifecycleStatus: "completed",
  });

  const opened = await openDispute.run({
    data: { bookingId: "booking1", reason: "quality issue" },
    auth: { uid: "student1", token: {} },
  });
  return opened.disputeId;
}

test("integration: resolve favor_student creates manual_pending refund ledger", async () => {
  await clearFirestore();
  const disputeId = await seedDisputedBooking();

  const res = await resolveDispute.run({
    data: {
      bookingId: "booking1",
      disputeId,
      resolution: "favor_student",
      reason: "teacher fault",
      idempotencyKey: "resolve-1",
    },
    auth: { uid: "admin1", token: { admin: true } },
  });

  assert.equal(res.lifecycleStatus, "refunded");
  assert.ok(res.refundId);
  assert.equal(res.refundExecutionStatus, "manual_pending");

  const refund = await db()
    .collection("quran_session_refunds")
    .doc(res.refundId!)
    .get();
  assert.equal(refund.get("status"), "manual_pending");
  assert.equal(refund.get("bookingId"), "booking1");
  assert.equal(refund.get("disputeId"), disputeId);

  const booking = await db().collection("quran_bookings").doc("booking1").get();
  assert.equal(booking.get("lifecycleStatus"), "refunded");
  assert.equal(booking.get("refundExecutionStatus"), "manual_pending");
});

test("integration: resolve with_compensation creates manual_pending compensation ledger", async () => {
  await clearFirestore();
  const disputeId = await seedDisputedBooking();

  const res = await resolveDispute.run({
    data: {
      bookingId: "booking1",
      disputeId,
      resolution: "with_compensation",
      reason: "goodwill credit",
      idempotencyKey: "resolve-comp-1",
    },
    auth: { uid: "admin1", token: { admin: true } },
  });

  assert.equal(res.lifecycleStatus, "compensated");
  assert.ok(res.compensationId);
  assert.equal(res.compensationExecutionStatus, "manual_pending");

  const compensation = await db()
    .collection("quran_session_compensations")
    .doc(res.compensationId!)
    .get();
  assert.equal(compensation.get("status"), "manual_pending");
  assert.equal(compensation.get("type"), "manual_review");
});

test("integration: duplicate dispute resolution does not duplicate ledger", async () => {
  await clearFirestore();
  const disputeId = await seedDisputedBooking();

  const payload = {
    bookingId: "booking1",
    disputeId,
    resolution: "favor_student" as const,
    reason: "teacher fault",
    idempotencyKey: "resolve-dup",
  };
  const auth = { uid: "admin1", token: { admin: true } };

  const first = await resolveDispute.run({ data: payload, auth });
  const second = await resolveDispute.run({ data: payload, auth });

  assert.equal(first.refundId, second.refundId);
  const refunds = await db().collection("quran_session_refunds").get();
  assert.equal(refunds.size, 1);
});
