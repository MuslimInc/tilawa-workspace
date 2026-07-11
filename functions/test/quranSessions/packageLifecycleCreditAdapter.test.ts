import test from "node:test";
import assert from "node:assert/strict";

import {
  decidePackageCreditForLifecycle,
  isLateStudentCancellation,
} from "../../src/quranSessions/packages/packageLifecycleCreditAdapter";
import type { LifecycleStatus } from "../../src/quranSessions/sessionLifecycleService";
import {
  consume,
  reserve,
  restore,
  issuedCounters,
} from "../../src/quranSessions/packages/packageCreditService";
import { isCountersConsistent } from "../../src/quranSessions/packages/packageTypes";

// Every terminal status maps to a defined decision.
const EXPECTED: Record<string, { op: string; extend?: boolean; review?: boolean }> = {
  completed: { op: "consume" },
  cancelled_by_teacher: { op: "restore", extend: true },
  cancelled_by_admin: { op: "restore", extend: false },
  teacher_no_show: { op: "restore", extend: true },
  student_no_show: { op: "consume" },
  both_no_show: { op: "restore", extend: true },
  rejected_by_tutor: { op: "restore", extend: false },
  expired: { op: "restore", extend: false },
  incomplete: { op: "none", review: true },
  disputed: { op: "none", review: true },
  compensated: { op: "none", review: false },
  refunded: { op: "none", review: false },
};

for (const [status, exp] of Object.entries(EXPECTED)) {
  test(`decision for ${status} → ${exp.op}`, () => {
    const d = decidePackageCreditForLifecycle({ status: status as LifecycleStatus });
    assert.equal(d.op, exp.op);
    if (exp.extend !== undefined) assert.equal(d.extendValidity, exp.extend);
    if (exp.review !== undefined) assert.equal(d.manualReview, exp.review);
  });
}

test("student cancellation before cutoff restores, no extend", () => {
  const d = decidePackageCreditForLifecycle({
    status: "cancelled_by_student",
    lateStudentCancellation: false,
  });
  assert.equal(d.op, "restore");
  assert.equal(d.extendValidity, false);
});

test("late student cancellation consumes the credit", () => {
  const d = decidePackageCreditForLifecycle({
    status: "cancelled_by_student",
    lateStudentCancellation: true,
  });
  assert.equal(d.op, "consume");
});

test("non-terminal statuses leave the reservation active", () => {
  for (const s of [
    "draft",
    "pending_payment",
    "pending_tutor_approval",
    "scheduled",
    "confirmed",
    "in_progress",
    "rescheduled",
  ] as LifecycleStatus[]) {
    const d = decidePackageCreditForLifecycle({ status: s });
    assert.equal(d.op, "none", s);
    assert.equal(d.manualReview, false, s);
  }
});

test("no terminal status is left undefined", () => {
  const terminal: LifecycleStatus[] = [
    "cancelled_by_student",
    "cancelled_by_teacher",
    "cancelled_by_admin",
    "teacher_no_show",
    "student_no_show",
    "both_no_show",
    "incomplete",
    "completed",
    "disputed",
    "compensated",
    "refunded",
    "expired",
    "rejected_by_tutor",
  ];
  for (const s of terminal) {
    const d = decidePackageCreditForLifecycle({ status: s });
    assert.ok(["consume", "restore", "none"].includes(d.op), s);
    assert.ok(d.reasonCode.length > 0, s);
  }
});

test("isLateStudentCancellation boundary is inclusive at the cutoff", () => {
  const start = Date.parse("2026-07-11T18:00:00.000Z");
  const cutoffH = 12;
  const cutoff = start - cutoffH * 3600_000; // 06:00
  assert.equal(isLateStudentCancellation(start, cutoff - 1, cutoffH), false);
  assert.equal(isLateStudentCancellation(start, cutoff, cutoffH), true);
  assert.equal(isLateStudentCancellation(start, cutoff + 1, cutoffH), true);
});

// Applying the decision through the credit service keeps counters consistent.
test("consume decision applied to a reservation stays consistent", () => {
  const reserved = reserve("pkg_1", issuedCounters(8), "bk_1");
  assert.ok(reserved.ok);
  if (!reserved.ok) return;
  const d = decidePackageCreditForLifecycle({ status: "completed" });
  assert.equal(d.op, "consume");
  const r = consume("pkg_1", reserved.counters, "bk_1", "sess_1", d.reasonCode);
  assert.ok(r.ok);
  if (r.ok) {
    assert.equal(r.counters.consumedCredits, 1);
    assert.equal(isCountersConsistent(r.counters), true);
  }
});

test("restore decision applied to a reservation stays consistent", () => {
  const reserved = reserve("pkg_1", issuedCounters(8), "bk_1");
  assert.ok(reserved.ok);
  if (!reserved.ok) return;
  const d = decidePackageCreditForLifecycle({ status: "teacher_no_show" });
  assert.equal(d.op, "restore");
  const r = restore("pkg_1", reserved.counters, "bk_1", "sess_1", d.reasonCode);
  assert.ok(r.ok);
  if (r.ok) {
    assert.equal(r.counters.availableCredits, 8);
    assert.equal(r.counters.restoredCredits, 1);
    assert.equal(isCountersConsistent(r.counters), true);
  }
});
