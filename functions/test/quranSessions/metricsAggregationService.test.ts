import test from "node:test";
import assert from "node:assert/strict";
import {
  computeCancellationRate90d,
  terminalTransitionForLifecycleStatus,
} from "../../src/quranSessions/metricsAggregationService";

test("terminalTransitionForLifecycleStatus maps cancellations", () => {
  assert.deepEqual(
    terminalTransitionForLifecycleStatus(
      "cancelled_by_teacher",
      "teacher-1",
      "student-1",
    ),
    { type: "cancelled_by_teacher", teacherId: "teacher-1" },
  );
  assert.deepEqual(
    terminalTransitionForLifecycleStatus(
      "cancelled_by_student",
      "teacher-1",
      "student-1",
    ),
    { type: "cancelled_by_student", studentId: "student-1" },
  );
});

test("terminalTransitionForLifecycleStatus maps no-show classifications", () => {
  assert.deepEqual(
    terminalTransitionForLifecycleStatus(
      "both_no_show",
      "teacher-1",
      "student-1",
    ),
    { type: "both_no_show", teacherId: "teacher-1", studentId: "student-1" },
  );
  assert.equal(
    terminalTransitionForLifecycleStatus(
      "pending_payment",
      "teacher-1",
      "student-1",
    ),
    null,
  );
});

test("computeCancellationRate90d guards zero denominator", () => {
  assert.equal(computeCancellationRate90d(2, 0), 0);
  assert.equal(computeCancellationRate90d(1, 4), 0.25);
});
