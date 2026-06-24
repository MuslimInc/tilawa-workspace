import test from "node:test";
import assert from "node:assert/strict";

import { assertRescheduleCounterpartyOnly } from "../../src/quranSessions/sessionAuth";

test("assertRescheduleCounterpartyOnly rejects requester self-response", () => {
  assert.throws(
    () => assertRescheduleCounterpartyOnly("student_1", "student_1"),
    (error: { code?: string; message?: string }) =>
      error.code === "permission-denied" &&
      error.message?.includes("cannot respond") === true,
  );
});

test("assertRescheduleCounterpartyOnly allows counterparty response", () => {
  assert.doesNotThrow(() =>
    assertRescheduleCounterpartyOnly("teacher_1", "student_1"),
  );
});

test("assertRescheduleCounterpartyOnly allows missing requestedByUserId", () => {
  assert.doesNotThrow(() =>
    assertRescheduleCounterpartyOnly("student_1", undefined),
  );
});
