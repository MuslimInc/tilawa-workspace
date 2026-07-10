import test from "node:test";
import assert from "node:assert/strict";

import { isWithinJoinWindow } from "../../src/quranSessions/sessionJoinWindowPolicy";
import { shouldTransitionToInProgress } from "../../src/quranSessions/sessionInProgressTransitionPolicy";
import { resolveSessionAllowedActions } from "../../src/quranSessions/sessionAllowedActionsService";
import { BOOKING_IDEMPOTENCY_DEDUPE_MS } from "../../src/quranSessions/platformSchedulingPolicy";

test("join window opens 15m before startsAt until endsAt", () => {
  const startsAt = new Date("2024-06-01T12:00:00.000Z");
  const endsAt = new Date("2024-06-01T13:00:00.000Z");
  assert.equal(
    isWithinJoinWindow({
      startsAt,
      endsAt,
      now: new Date("2024-06-01T11:44:59.000Z"),
    }),
    false,
  );
  assert.equal(
    isWithinJoinWindow({
      startsAt,
      endsAt,
      now: new Date("2024-06-01T11:45:00.000Z"),
    }),
    true,
  );
  assert.equal(
    isWithinJoinWindow({
      startsAt,
      endsAt,
      now: new Date("2024-06-01T13:00:00.000Z"),
    }),
    true,
  );
  assert.equal(
    isWithinJoinWindow({
      startsAt,
      endsAt,
      now: new Date("2024-06-01T13:00:01.000Z"),
    }),
    false,
  );
});

test("inProgress requires join at or after startsAt", () => {
  const startsAt = new Date("2024-06-01T12:00:00.000Z");
  assert.equal(
    shouldTransitionToInProgress({
      startsAt,
      now: new Date("2024-06-01T12:00:00.000Z"),
      joinEventAtMs: startsAt.getTime() - 1,
    }),
    false,
  );
  assert.equal(
    shouldTransitionToInProgress({
      startsAt,
      now: new Date("2024-06-01T12:00:00.000Z"),
      joinEventAtMs: startsAt.getTime(),
    }),
    true,
  );
});

test("allowed actions include cancel for pending tutor approval student", () => {
  const actions = resolveSessionAllowedActions({
    lifecycleStatus: "pending_tutor_approval",
    actorRole: "student",
    startsAt: new Date("2099-01-01T12:00:00.000Z"),
    endsAt: new Date("2099-01-01T13:00:00.000Z"),
    now: new Date("2099-01-01T00:00:00.000Z"),
  });
  assert.ok(actions.includes("cancel"));
  assert.equal(actions.includes("join"), false);
});

test("booking idempotency dedupe window is 24 hours", () => {
  assert.equal(BOOKING_IDEMPOTENCY_DEDUPE_MS, 24 * 60 * 60 * 1000);
});
