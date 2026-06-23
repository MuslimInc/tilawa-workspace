import test from "node:test";
import assert from "node:assert/strict";
import { legacyStatusForLifecycle } from "../../src/quranSessions/sessionLifecycleService";

test("maps scheduled lifecycle to confirmed legacy", () => {
  assert.equal(legacyStatusForLifecycle("scheduled"), "confirmed");
});

test("maps cancellation lifecycle to cancelled legacy", () => {
  assert.equal(legacyStatusForLifecycle("cancelled_by_student"), "cancelled");
  assert.equal(legacyStatusForLifecycle("cancelled_by_teacher"), "cancelled");
});

test("maps expired lifecycle to rejected legacy", () => {
  assert.equal(legacyStatusForLifecycle("expired"), "rejected");
});
