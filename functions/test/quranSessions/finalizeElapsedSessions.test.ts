import test from "node:test";
import assert from "node:assert/strict";

import {
  classifyElapsedSession,
  COMPLETION_MIN_CONNECTED_RATIO,
  type ElapsedSessionEvidence,
} from "../../src/quranSessions/finalizeElapsedSessions";

const THIRTY_MINUTES_MS = 30 * 60 * 1000;

function evidence(
  overrides: Partial<ElapsedSessionEvidence> = {},
): ElapsedSessionEvidence {
  return {
    lifecycleStatus: "confirmed",
    plannedDurationMs: THIRTY_MINUTES_MS,
    trackingExists: true,
    teacherEverConnected: false,
    studentEverConnected: false,
    bothParticipantsConnectedSeconds: 0,
    ...overrides,
  };
}

test("no telemetry doc at all → expired (no evidence, no penalty)", () => {
  const outcome = classifyElapsedSession(
    evidence({ trackingExists: false }),
  );
  assert.equal(outcome.action, "expire_unattended_session");
  assert.equal(outcome.noShowClassification, null);
});

test("teacher joined, student never → student_no_show", () => {
  const outcome = classifyElapsedSession(
    evidence({ teacherEverConnected: true }),
  );
  assert.equal(outcome.action, "mark_student_no_show");
  assert.equal(outcome.noShowClassification, "student_no_show");
});

test("student joined, teacher never → teacher_no_show", () => {
  const outcome = classifyElapsedSession(
    evidence({ studentEverConnected: true }),
  );
  assert.equal(outcome.action, "mark_teacher_no_show");
  assert.equal(outcome.noShowClassification, "teacher_no_show");
});

test("telemetry exists but neither ever connected → both_no_show", () => {
  const outcome = classifyElapsedSession(evidence());
  assert.equal(outcome.action, "mark_both_no_show");
  assert.equal(outcome.noShowClassification, "both_no_show");
});

test("both connected for enough of the planned duration → completed", () => {
  const halfSessionSeconds =
    (THIRTY_MINUTES_MS / 1000) * COMPLETION_MIN_CONNECTED_RATIO;
  const outcome = classifyElapsedSession(
    evidence({
      teacherEverConnected: true,
      studentEverConnected: true,
      bothParticipantsConnectedSeconds: halfSessionSeconds,
    }),
  );
  assert.equal(outcome.action, "finalize_completed_session");
  assert.equal(outcome.noShowClassification, null);
});

test("both connected but call too short → incomplete", () => {
  const outcome = classifyElapsedSession(
    evidence({
      teacherEverConnected: true,
      studentEverConnected: true,
      bothParticipantsConnectedSeconds: 60,
    }),
  );
  assert.equal(outcome.action, "mark_incomplete");
  assert.equal(outcome.noShowClassification, null);
});

test("in_progress with a long enough call → complete_session", () => {
  const outcome = classifyElapsedSession(
    evidence({
      lifecycleStatus: "in_progress",
      teacherEverConnected: true,
      studentEverConnected: true,
      bothParticipantsConnectedSeconds: THIRTY_MINUTES_MS / 1000,
    }),
  );
  assert.equal(outcome.action, "complete_session");
});

test("in_progress with a short call → incomplete", () => {
  const outcome = classifyElapsedSession(
    evidence({
      lifecycleStatus: "in_progress",
      bothParticipantsConnectedSeconds: 30,
    }),
  );
  assert.equal(outcome.action, "mark_incomplete");
});

test("zero connected seconds never counts as completed even for a zero-duration record", () => {
  const outcome = classifyElapsedSession(
    evidence({
      lifecycleStatus: "in_progress",
      plannedDurationMs: 0,
      bothParticipantsConnectedSeconds: 0,
    }),
  );
  assert.equal(outcome.action, "mark_incomplete");
});
