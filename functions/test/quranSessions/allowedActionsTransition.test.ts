import test from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";

import { allowedActionsPatchFromAggregate } from "../../src/quranSessions/aggregateWriteService";
import type { SessionAllowedAction } from "../../src/quranSessions/sessionAllowedActionsService";

const startsAt = new Date("2099-06-01T12:00:00.000Z");
const endsAt = new Date("2099-06-01T13:00:00.000Z");
const timing = {
  startsAt: Timestamp.fromDate(startsAt),
  endsAt: Timestamp.fromDate(endsAt),
  joinWindowLeadMs: 15 * 60 * 1000,
};

function studentActions(status: string): SessionAllowedAction[] {
  const patch = allowedActionsPatchFromAggregate(status, timing);
  return patch.allowedActionsStudent as SessionAllowedAction[];
}

function teacherActions(status: string): SessionAllowedAction[] {
  const patch = allowedActionsPatchFromAggregate(status, timing);
  return patch.allowedActionsTeacher as SessionAllowedAction[];
}

test("pending tutor approval exposes student cancel and teacher respond", () => {
  assert.ok(studentActions("pending_tutor_approval").includes("cancel"));
  assert.equal(
    studentActions("pending_tutor_approval").includes("join"),
    false,
  );
  assert.ok(
    teacherActions("pending_tutor_approval").includes("respondToBookingRequest"),
  );
});

test("scheduled exposes cancel before join window opens", () => {
  assert.ok(studentActions("scheduled").includes("cancel"));
  assert.equal(studentActions("scheduled").includes("join"), false);
  assert.ok(teacherActions("scheduled").includes("cancel"));
});

test("cancelled booking removes join and cancel actions", () => {
  for (const status of [
    "cancelled_by_student",
    "cancelled_by_teacher",
    "cancelled_by_admin",
  ]) {
    assert.equal(studentActions(status).includes("join"), false);
    assert.equal(studentActions(status).includes("cancel"), false);
    assert.ok(studentActions(status).includes("openDispute"));
  }
});

test("completed booking exposes student review only", () => {
  assert.ok(studentActions("completed").includes("submitReview"));
  assert.equal(teacherActions("completed").includes("submitReview"), false);
  assert.equal(studentActions("completed").includes("join"), false);
});

test("in_progress allows join inside window", () => {
  const patch = allowedActionsPatchFromAggregate("in_progress", {
    ...timing,
    startsAt: Timestamp.fromDate(new Date(Date.now() - 60_000)),
    endsAt: Timestamp.fromDate(new Date(Date.now() + 3_600_000)),
  });
  assert.ok(
    (patch.allowedActionsStudent as SessionAllowedAction[]).includes("join"),
  );
});

test("allowed actions patch includes updatedAt timestamp", () => {
  const patch = allowedActionsPatchFromAggregate("scheduled", timing);
  assert.equal(typeof patch.allowedActionsUpdatedAt, "string");
});
