/**
 * Pure validation and guard logic for the user deletion callables.
 * No firebase imports so it unit-tests without an emulator; callables map
 * DeletionGuardError.code onto HttpsError codes 1:1.
 */

export type GuardErrorCode =
  | "invalid-argument"
  | "permission-denied"
  | "failed-precondition"
  | "not-found";

export class DeletionGuardError extends Error {
  constructor(
    readonly code: GuardErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "DeletionGuardError";
  }
}

export const MIN_REASON_LENGTH = 10;
export const MAX_REASON_LENGTH = 500;

export interface RequestUserDeletionInput {
  targetUserId: string;
  reason: string;
  confirmEmail: string;
}

export interface CancelUserDeletionInput {
  targetUserId: string;
  reason: string;
}

export interface SelfAccountDeletionInput {
  reason: string;
  confirmEmail: string;
}

function requireReason(raw: unknown): string {
  const reason = typeof raw === "string" ? raw.trim() : "";
  if (reason.length < MIN_REASON_LENGTH) {
    throw new DeletionGuardError(
      "invalid-argument",
      `reason required (min ${MIN_REASON_LENGTH} characters).`,
    );
  }
  if (reason.length > MAX_REASON_LENGTH) {
    throw new DeletionGuardError(
      "invalid-argument",
      `reason too long (max ${MAX_REASON_LENGTH} characters).`,
    );
  }
  return reason;
}

function requireTargetUserId(raw: unknown): string {
  const targetUserId = typeof raw === "string" ? raw.trim() : "";
  if (!targetUserId) {
    throw new DeletionGuardError("invalid-argument", "targetUserId required.");
  }
  return targetUserId;
}

export function validateRequestUserDeletionInput(
  data: unknown,
): RequestUserDeletionInput {
  const record = (data ?? {}) as Record<string, unknown>;
  const targetUserId = requireTargetUserId(record.targetUserId);
  const reason = requireReason(record.reason);
  const confirmEmail =
    typeof record.confirmEmail === "string" ? record.confirmEmail.trim() : "";
  if (!confirmEmail) {
    throw new DeletionGuardError("invalid-argument", "confirmEmail required.");
  }
  return { targetUserId, reason, confirmEmail };
}

export function validateCancelUserDeletionInput(
  data: unknown,
): CancelUserDeletionInput {
  const record = (data ?? {}) as Record<string, unknown>;
  return {
    targetUserId: requireTargetUserId(record.targetUserId),
    reason: requireReason(record.reason),
  };
}

export function validateSelfAccountDeletionInput(
  data: unknown,
): SelfAccountDeletionInput {
  const record = (data ?? {}) as Record<string, unknown>;
  const reason = requireReason(record.reason);
  const confirmEmail =
    typeof record.confirmEmail === "string" ? record.confirmEmail.trim() : "";
  if (!confirmEmail) {
    throw new DeletionGuardError("invalid-argument", "confirmEmail required.");
  }
  return { reason, confirmEmail };
}

export interface DeletableTarget {
  uid: string;
  email: string | null;
  customClaims: Record<string, unknown>;
}

function assertDeletionEmailConfirmation(input: {
  target: DeletableTarget;
  confirmEmail: string;
}): void {
  const provided = input.target.email
    ? input.confirmEmail.toLowerCase()
    : input.confirmEmail;
  if (provided === "delete") {
    return;
  }
  const expected = input.target.email?.toLowerCase() ?? input.target.uid;
  if (provided !== expected) {
    throw new DeletionGuardError(
      "failed-precondition",
      input.target.email
        ? "confirmEmail must match the target account's email or DELETE."
        : "Target has no email; confirmEmail must equal the target uid or DELETE.",
    );
  }
}

/**
 * Caller-independent guards for requestUserDeletion. Order is part of the
 * contract (tested): self-deletion, admin target, then email confirmation.
 * Targets without an email (phone/anonymous accounts) confirm with the uid.
 */
export function assertTargetDeletable(input: {
  callerUid: string;
  target: DeletableTarget;
  confirmEmail: string;
}): void {
  if (input.target.uid === input.callerUid) {
    throw new DeletionGuardError(
      "failed-precondition",
      "Self-deletion is not allowed.",
    );
  }
  if (input.target.customClaims.admin === true) {
    throw new DeletionGuardError(
      "failed-precondition",
      "Cannot delete an admin account. Remove the admin claim first.",
    );
  }
  assertDeletionEmailConfirmation(input);
}

/**
 * Guards for requestSelfAccountDeletion: caller must match target, admin
 * accounts are rejected, then the same email confirmation as admin deletion.
 */
export function assertSelfDeletable(input: {
  callerUid: string;
  target: DeletableTarget;
  confirmEmail: string;
}): void {
  if (input.target.uid !== input.callerUid) {
    throw new DeletionGuardError(
      "permission-denied",
      "You can only delete your own account.",
    );
  }
  if (input.target.customClaims.admin === true) {
    throw new DeletionGuardError(
      "failed-precondition",
      "Admin accounts cannot be deleted via self-service.",
    );
  }
  assertDeletionEmailConfirmation(input);
}

export function computePurgeAfterMs(nowMs: number, graceDays: number): number {
  return nowMs + graceDays * 24 * 60 * 60 * 1000;
}

