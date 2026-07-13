import test from "node:test";
import assert from "node:assert/strict";

import {
  adjust,
  consume,
  deterministicMovementId,
  expire,
  issue,
  issuedCounters,
  reserve,
  restore,
  type CreditResult,
} from "../../src/quranSessions/packages/packageCreditService";
import {
  isCountersConsistent,
  type StudentPackageCounters,
} from "../../src/quranSessions/packages/packageTypes";

function ok(result: CreditResult): StudentPackageCounters {
  assert.equal(result.ok, true, `expected ok, got ${JSON.stringify(result)}`);
  if (!result.ok) throw new Error("unreachable");
  assert.equal(isCountersConsistent(result.counters), true);
  return result.counters;
}

const PKG = "pkg_1";

test("issuedCounters mints n consistent available credits", () => {
  const c = issuedCounters(8);
  assert.equal(c.availableCredits, 8);
  assert.equal(c.issuedCredits, 8);
  assert.equal(isCountersConsistent(c), true);
});

test("issue produces an issue movement keyed by order id", () => {
  const r = issue(PKG, 8, "ord_9");
  const c = ok(r);
  assert.equal(c.availableCredits, 8);
  if (r.ok) {
    assert.equal(r.movement.type, "issue");
    assert.equal(r.movement.quantity, 8);
    assert.equal(r.movement.movementId, "pkg_1__issue__ord_9");
  }
});

test("issue rejects non-positive session count", () => {
  const r = issue(PKG, 0, "ord_1");
  assert.equal(r.ok, false);
});

test("reserve moves available → reserved", () => {
  const c = ok(reserve(PKG, issuedCounters(8), "bk_1"));
  assert.equal(c.availableCredits, 7);
  assert.equal(c.reservedCredits, 1);
});

test("reserve fails when no credit is available", () => {
  const exhausted = { ...issuedCounters(8), availableCredits: 0, expiredCredits: 8 };
  const r = reserve(PKG, exhausted, "bk_1");
  assert.equal(r.ok, false);
  if (!r.ok) assert.equal(r.error.code, "no_credit_available");
});

test("consume moves reserved → consumed and is terminal", () => {
  const reserved = ok(reserve(PKG, issuedCounters(8), "bk_1"));
  const c = ok(consume(PKG, reserved, "bk_1", "sess_1", "session_completed"));
  assert.equal(c.reservedCredits, 0);
  assert.equal(c.consumedCredits, 1);
  assert.equal(c.availableCredits, 7);
});

test("consume fails with no reservation", () => {
  const r = consume(PKG, issuedCounters(8), "bk_1", "sess_1", "session_completed");
  assert.equal(r.ok, false);
  if (!r.ok) assert.equal(r.error.code, "no_reservation_to_finalize");
});

test("restore moves reserved → available and tallies restored", () => {
  const reserved = ok(reserve(PKG, issuedCounters(8), "bk_1"));
  const c = ok(restore(PKG, reserved, "bk_1", "sess_1", "teacher_no_show"));
  assert.equal(c.reservedCredits, 0);
  assert.equal(c.availableCredits, 8);
  assert.equal(c.restoredCredits, 1);
  assert.equal(c.consumedCredits, 0);
});

test("full reserve→restore→reserve→consume cycle stays consistent", () => {
  let c = issuedCounters(8);
  c = ok(reserve(PKG, c, "bk_1"));
  c = ok(restore(PKG, c, "bk_1", "sess_1", "learner_early_cancel"));
  c = ok(reserve(PKG, c, "bk_2"));
  c = ok(consume(PKG, c, "bk_2", "sess_2", "session_completed"));
  assert.equal(c.availableCredits, 7);
  assert.equal(c.reservedCredits, 0);
  assert.equal(c.consumedCredits, 1);
  assert.equal(c.restoredCredits, 1);
  assert.equal(isCountersConsistent(c), true);
});

test("expire retires all available credits", () => {
  const reserved = ok(reserve(PKG, issuedCounters(8), "bk_1"));
  const c = ok(expire(PKG, reserved));
  assert.equal(c.availableCredits, 0);
  assert.equal(c.expiredCredits, 7);
  // The single reserved credit is untouched, to be finalized by its booking.
  assert.equal(c.reservedCredits, 1);
});

test("expire fails when nothing is available", () => {
  const c = { ...issuedCounters(8), availableCredits: 0, expiredCredits: 8 };
  const r = expire(PKG, c);
  assert.equal(r.ok, false);
  if (!r.ok) assert.equal(r.error.code, "nothing_to_expire");
});

test("positive adjustment mints available credits", () => {
  const c = ok(adjust(PKG, issuedCounters(8), 2, "goodwill", "admin_1", "idem_1"));
  assert.equal(c.availableCredits, 10);
  assert.equal(c.adjustPositiveTotal, 2);
});

test("negative adjustment removes available credits", () => {
  const c = ok(adjust(PKG, issuedCounters(8), -3, "correction", "admin_1", "idem_2"));
  assert.equal(c.availableCredits, 5);
  assert.equal(c.adjustNegativeTotal, 3);
});

test("negative adjustment cannot underflow available", () => {
  const r = adjust(PKG, issuedCounters(2), -3, "correction", "admin_1", "idem_3");
  assert.equal(r.ok, false);
  if (!r.ok) assert.equal(r.error.code, "adjustment_underflow");
});

test("zero / non-integer adjustment is rejected", () => {
  assert.equal(adjust(PKG, issuedCounters(8), 0, "x", "a", "i").ok, false);
  assert.equal(adjust(PKG, issuedCounters(8), 1.5, "x", "a", "i").ok, false);
});

test("adjustment movement ids are deterministic per idempotency key", () => {
  const a = adjust(PKG, issuedCounters(8), 1, "x", "admin_1", "idem_same");
  const b = adjust(PKG, issuedCounters(8), 1, "x", "admin_1", "idem_same");
  assert.equal(a.ok && b.ok && a.movement.movementId, "pkg_1__adjust_positive__idem_same");
  if (a.ok && b.ok) assert.equal(a.movement.movementId, b.movement.movementId);
});

test("deterministicMovementId sanitizes unsafe characters", () => {
  const id = deterministicMovementId(PKG, "reserve", "bk/1 with:weird#chars");
  assert.equal(id, "pkg_1__reserve__bk_1_with_weird_chars");
});

test("reserve is deterministic per booking id (idempotent replay)", () => {
  const a = reserve(PKG, issuedCounters(8), "bk_42");
  const b = reserve(PKG, issuedCounters(8), "bk_42");
  assert.equal(a.ok && a.movement.movementId, "pkg_1__reserve__bk_42");
  if (a.ok && b.ok) assert.equal(a.movement.movementId, b.movement.movementId);
});

test("final-credit contention: only the first reserve succeeds from one credit", () => {
  // Model two concurrent attempts reading the same single-credit snapshot.
  const snapshot: StudentPackageCounters = {
    ...issuedCounters(8),
    availableCredits: 1,
    reservedCredits: 0,
    consumedCredits: 7,
  };
  const first = reserve(PKG, snapshot, "bk_a");
  const firstCounters = ok(first);
  // A transaction commits `first`; the second attempt now reads that result.
  const second = reserve(PKG, firstCounters, "bk_b");
  assert.equal(second.ok, false);
  if (!second.ok) assert.equal(second.error.code, "no_credit_available");
});
