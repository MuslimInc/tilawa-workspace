import test from "node:test";
import assert from "node:assert/strict";

import {
  cancelActionForRole,
  noShowActionForClassification,
  validateTransition,
} from "../../src/quranSessions/sessionLifecycleGuard";

/** Two hours — safely outside the 1 h student cancel notice window. */
const STUDENT_CANCEL_SAFE_NOTICE_MS = 2 * 60 * 60 * 1000;

/** Thirty seconds — safely inside the 1 h student cancel notice window. */
const STUDENT_CANCEL_LATE_NOTICE_MS = 30 * 1000;

test("allows tutor accept from pending_tutor_approval", () => {
  const result = validateTransition({
    currentStatus: "pending_tutor_approval",
    action: "accept_booking_request",
    actor: "teacher",
  });
  assert.equal(result.to, "scheduled");
});

test("allows student cancel from pending_tutor_approval without notice guard", () => {
  const result = validateTransition({
    currentStatus: "pending_tutor_approval",
    action: "cancel_by_student",
    actor: "student",
    reason: "changed mind",
    sessionStartsAt: new Date(Date.now() + STUDENT_CANCEL_LATE_NOTICE_MS),
  });
  assert.equal(result.to, "cancelled_by_student");
});
  const result = validateTransition({
    currentStatus: "scheduled",
    action: "cancel_by_student",
    actor: "student",
    reason: "plans changed",
    sessionStartsAt: new Date(Date.now() + STUDENT_CANCEL_SAFE_NOTICE_MS),
  });
  assert.equal(result.to, "cancelled_by_student");
});

test("blocks student cancel inside notice window", () => {
  assert.throws(
    () =>
      validateTransition({
        currentStatus: "scheduled",
        action: "cancel_by_student",
        actor: "student",
        reason: "late",
        sessionStartsAt: new Date(Date.now() + STUDENT_CANCEL_LATE_NOTICE_MS),
      }),
    (error: { details?: { code?: string } }) =>
      error.details?.code === "late_student_cancellation_blocked",
  );
});

test("blocks complete session from scheduled", () => {
  assert.throws(
    () =>
      validateTransition({
        currentStatus: "scheduled",
        action: "complete_session",
        actor: "teacher",
      }),
    (error: { details?: { code?: string } }) =>
      error.details?.code === "invalid_transition",
  );
});

test("blocks unauthorized teacher on admin cancel", () => {
  assert.throws(
    () =>
      validateTransition({
        currentStatus: "scheduled",
        action: "cancel_by_admin",
        actor: "teacher",
        reason: "admin",
      }),
    (error: { details?: { code?: string } }) =>
      error.details?.code === "unauthorized_actor",
  );
});

test("maps no-show classification to guarded actions", () => {
  assert.equal(
    noShowActionForClassification("teacher_no_show"),
    "mark_teacher_no_show",
  );
  assert.equal(
    noShowActionForClassification("student_no_show"),
    "mark_student_no_show",
  );
  assert.equal(
    noShowActionForClassification("both_no_show"),
    "mark_both_no_show",
  );
});

test("maps cancel actor roles", () => {
  assert.equal(cancelActionForRole("student"), "cancel_by_student");
  assert.equal(cancelActionForRole("teacher"), "cancel_by_teacher");
  assert.equal(cancelActionForRole("admin"), "cancel_by_admin");
});

test("requires reason for open dispute", () => {
  assert.throws(
    () =>
      validateTransition({
        currentStatus: "completed",
        action: "open_dispute",
        actor: "student",
      }),
    (error: { details?: { code?: string } }) =>
      error.details?.code === "reason_required",
  );
});

test("allows admin refund from terminal states", () => {
  const result = validateTransition({
    currentStatus: "cancelled_by_student",
    action: "issue_refund",
    actor: "admin",
    reason: "goodwill",
  });
  assert.equal(result.to, "refunded");
});

test("expire reservation syncs from pending_payment", () => {
  const result = validateTransition({
    currentStatus: "pending_payment",
    action: "expire_reservation",
    actor: "system",
  });
  assert.equal(result.to, "expired");
});
