import test from "node:test";
import assert from "node:assert/strict";

import {
  DeletionGuardError,
  assertSelfDeletable,
  assertTargetDeletable,
  computePurgeAfterMs,
  validateCancelUserDeletionInput,
  validateRequestUserDeletionInput,
  validateSelfAccountDeletionInput,
} from "../src/userDeletion/userDeletionLogic";

function guardCode(fn: () => void): string {
  try {
    fn();
  } catch (error) {
    if (error instanceof DeletionGuardError) return error.code;
    throw error;
  }
  return "none";
}

const validInput = {
  targetUserId: "user-1",
  reason: "GDPR erasure request from support ticket 123",
  confirmEmail: "target@example.com",
};

test("validateRequestUserDeletionInput accepts valid input", () => {
  const parsed = validateRequestUserDeletionInput({
    ...validInput,
    targetUserId: "  user-1  ",
  });
  assert.equal(parsed.targetUserId, "user-1");
  assert.equal(parsed.reason, validInput.reason);
});

test("validateRequestUserDeletionInput rejects missing targetUserId", () => {
  assert.equal(
    guardCode(() =>
      validateRequestUserDeletionInput({ ...validInput, targetUserId: "" }),
    ),
    "invalid-argument",
  );
});

test("validateRequestUserDeletionInput rejects short reason", () => {
  assert.equal(
    guardCode(() =>
      validateRequestUserDeletionInput({ ...validInput, reason: "spam" }),
    ),
    "invalid-argument",
  );
});

test("validateRequestUserDeletionInput rejects overlong reason", () => {
  assert.equal(
    guardCode(() =>
      validateRequestUserDeletionInput({
        ...validInput,
        reason: "x".repeat(501),
      }),
    ),
    "invalid-argument",
  );
});

test("validateRequestUserDeletionInput rejects missing confirmEmail", () => {
  assert.equal(
    guardCode(() =>
      validateRequestUserDeletionInput({ ...validInput, confirmEmail: " " }),
    ),
    "invalid-argument",
  );
});

test("validateCancelUserDeletionInput requires reason", () => {
  assert.equal(
    guardCode(() =>
      validateCancelUserDeletionInput({ targetUserId: "user-1", reason: "" }),
    ),
    "invalid-argument",
  );
});

const selfValidInput = {
  reason: "Self-service account deletion from mobile app",
  confirmEmail: "target@example.com",
};

test("validateSelfAccountDeletionInput accepts valid input", () => {
  const parsed = validateSelfAccountDeletionInput(selfValidInput);
  assert.equal(parsed.reason, selfValidInput.reason);
  assert.equal(parsed.confirmEmail, selfValidInput.confirmEmail);
});

test("validateSelfAccountDeletionInput rejects short reason", () => {
  assert.equal(
    guardCode(() =>
      validateSelfAccountDeletionInput({ ...selfValidInput, reason: "short" }),
    ),
    "invalid-argument",
  );
});

test("validateSelfAccountDeletionInput rejects missing confirmEmail", () => {
  assert.equal(
    guardCode(() =>
      validateSelfAccountDeletionInput({ ...selfValidInput, confirmEmail: "" }),
    ),
    "invalid-argument",
  );
});

const target = {
  uid: "user-1",
  email: "target@example.com",
  customClaims: {} as Record<string, unknown>,
};

test("assertTargetDeletable rejects self-deletion", () => {
  assert.equal(
    guardCode(() =>
      assertTargetDeletable({
        callerUid: "user-1",
        target,
        confirmEmail: target.email,
      }),
    ),
    "failed-precondition",
  );
});

test("assertTargetDeletable rejects admin targets", () => {
  assert.equal(
    guardCode(() =>
      assertTargetDeletable({
        callerUid: "admin-1",
        target: { ...target, customClaims: { admin: true } },
        confirmEmail: target.email,
      }),
    ),
    "failed-precondition",
  );
});

test("assertTargetDeletable accepts DELETE as confirmation", () => {
  assertTargetDeletable({
    callerUid: "admin-1",
    target,
    confirmEmail: "DELETE",
  });
});

test("assertTargetDeletable rejects mismatched confirmEmail", () => {
  assert.equal(
    guardCode(() =>
      assertTargetDeletable({
        callerUid: "admin-1",
        target,
        confirmEmail: "other@example.com",
      }),
    ),
    "failed-precondition",
  );
});

test("assertTargetDeletable matches email case-insensitively", () => {
  assertTargetDeletable({
    callerUid: "admin-1",
    target,
    confirmEmail: "Target@Example.COM",
  });
});

test("assertTargetDeletable without email requires uid confirmation", () => {
  const noEmail = { ...target, email: null };
  assert.equal(
    guardCode(() =>
      assertTargetDeletable({
        callerUid: "admin-1",
        target: noEmail,
        confirmEmail: "whatever",
      }),
    ),
    "failed-precondition",
  );
  assertTargetDeletable({
    callerUid: "admin-1",
    target: noEmail,
    confirmEmail: "user-1",
  });
});

test("assertSelfDeletable rejects mismatched caller", () => {
  assert.equal(
    guardCode(() =>
      assertSelfDeletable({
        callerUid: "other-user",
        target,
        confirmEmail: target.email,
      }),
    ),
    "permission-denied",
  );
});

test("assertSelfDeletable rejects admin accounts", () => {
  assert.equal(
    guardCode(() =>
      assertSelfDeletable({
        callerUid: "user-1",
        target: { ...target, customClaims: { admin: true } },
        confirmEmail: target.email,
      }),
    ),
    "failed-precondition",
  );
});

test("assertSelfDeletable accepts matching caller and DELETE", () => {
  assertSelfDeletable({
    callerUid: "user-1",
    target,
    confirmEmail: "DELETE",
  });
});

test("assertSelfDeletable rejects mismatched confirmEmail", () => {
  assert.equal(
    guardCode(() =>
      assertSelfDeletable({
        callerUid: "user-1",
        target,
        confirmEmail: "other@example.com",
      }),
    ),
    "failed-precondition",
  );
});

test("computePurgeAfterMs adds the grace period in days", () => {
  const now = Date.UTC(2026, 0, 1);
  assert.equal(
    computePurgeAfterMs(now, 30),
    now + 30 * 24 * 60 * 60 * 1000,
  );
});

