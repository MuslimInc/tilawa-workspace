/**
 * Pure planning/validation for duplicate-email account cleanup.
 * Reuses DeletionGuardError codes for callable mapping.
 */

import { AuthAccountSummary } from "./authAccountLookup";
import {
  DeletionGuardError,
  MIN_REASON_LENGTH,
  MAX_REASON_LENGTH,
} from "./userDeletionLogic";

export type DuplicateDeletionMode = "keep_google" | "manual";

export interface DuplicateDeletionPlan {
  keepUserId: string;
  deleteUserIds: readonly string[];
}

export interface DuplicateDeletionRequestInput {
  email: string;
  reason: string;
  confirmEmail: string;
  keepUserId: string;
  deleteUserIds: readonly string[];
  forceDeleteGoogleAccount?: boolean;
}

function uniqueUids(uids: readonly string[]): string[] {
  return [...new Set(uids.map((uid) => uid.trim()).filter(Boolean))];
}

export function normalizeLookupEmail(raw: unknown): string {
  const email = typeof raw === "string" ? raw.trim().toLowerCase() : "";
  if (!email || !email.includes("@")) {
    throw new DeletionGuardError("invalid-argument", "Valid email required.");
  }
  return email;
}

export function validateDuplicateDeletionRequestInput(
  data: unknown,
): DuplicateDeletionRequestInput {
  const record = (data ?? {}) as Record<string, unknown>;
  const email = normalizeLookupEmail(record.email);
  const reason = typeof record.reason === "string" ? record.reason.trim() : "";
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
  const confirmEmail =
    typeof record.confirmEmail === "string" ? record.confirmEmail.trim() : "";
  if (
    confirmEmail.toLowerCase() !== email &&
    confirmEmail.toLowerCase() !== "delete"
  ) {
    throw new DeletionGuardError(
      "invalid-argument",
      "confirmEmail must match the target email or DELETE.",
    );
  }
  const keepUserId =
    typeof record.keepUserId === "string" ? record.keepUserId.trim() : "";
  if (!keepUserId) {
    throw new DeletionGuardError("invalid-argument", "keepUserId required.");
  }
  const deleteRaw = record.deleteUserIds;
  const deleteUserIds = Array.isArray(deleteRaw)
    ? uniqueUids(deleteRaw.filter((id): id is string => typeof id === "string"))
    : [];
  if (deleteUserIds.length === 0) {
    throw new DeletionGuardError(
      "invalid-argument",
      "deleteUserIds must list at least one account to delete.",
    );
  }
  return {
    email,
    reason,
    confirmEmail,
    keepUserId,
    deleteUserIds,
    forceDeleteGoogleAccount: record.forceDeleteGoogleAccount === true,
  };
}

export function buildKeepGoogleDeletionPlan(
  accounts: readonly Pick<
    AuthAccountSummary,
    "uid" | "hasGoogleProvider"
  >[],
): DuplicateDeletionPlan | null {
  if (accounts.length <= 1) {
    return null;
  }
  const googleAccounts = accounts.filter((account) => account.hasGoogleProvider);
  if (googleAccounts.length !== 1) {
    return null;
  }
  const keepUserId = googleAccounts[0]!.uid;
  const deleteUserIds = accounts
    .map((account) => account.uid)
    .filter((uid) => uid !== keepUserId);
  return { keepUserId, deleteUserIds };
}

/**
 * Validates an explicit keep/delete plan against Auth account facts and
 * safety rules. Throws DeletionGuardError on unsafe combinations.
 */
export function validateDuplicateDeletionPlan(input: {
  callerUid: string;
  accounts: readonly AuthAccountSummary[];
  keepUserId: string;
  deleteUserIds: readonly string[];
  forceDeleteGoogleAccount?: boolean;
}): DuplicateDeletionPlan {
  const accountByUid = new Map(
    input.accounts.map((account) => [account.uid, account]),
  );
  const keepAccount = accountByUid.get(input.keepUserId);
  if (!keepAccount) {
    throw new DeletionGuardError(
      "invalid-argument",
      "keepUserId is not among the accounts for this email.",
    );
  }

  const deleteUserIds = uniqueUids(input.deleteUserIds);
  if (deleteUserIds.includes(input.keepUserId)) {
    throw new DeletionGuardError(
      "failed-precondition",
      "The kept account cannot also be marked for deletion.",
    );
  }

  if (input.accounts.length <= 1) {
    throw new DeletionGuardError(
      "failed-precondition",
      "Only one account exists for this email; use single-account deletion.",
    );
  }

  const googleAccounts = input.accounts.filter(
    (account) => account.hasGoogleProvider,
  );

  for (const uid of deleteUserIds) {
    const account = accountByUid.get(uid);
    if (!account) {
      throw new DeletionGuardError(
        "invalid-argument",
        `deleteUserIds contains unknown uid ${uid}.`,
      );
    }
    if (uid === input.callerUid) {
      throw new DeletionGuardError(
        "failed-precondition",
        "Self-deletion is not allowed.",
      );
    }
    if (account.customClaims.admin === true) {
      throw new DeletionGuardError(
        "failed-precondition",
        `Cannot delete admin account ${uid}. Remove the admin claim first.`,
      );
    }
  }

  const deletingGoogle = deleteUserIds.some(
    (uid) => accountByUid.get(uid)?.hasGoogleProvider === true,
  );
  const soleGoogle =
    googleAccounts.length === 1 ? googleAccounts[0]!.uid : null;

  if (deletingGoogle && input.forceDeleteGoogleAccount !== true) {
    throw new DeletionGuardError(
      "failed-precondition",
      "Deleting a Google Sign-In account requires forceDeleteGoogleAccount.",
    );
  }

  if (
    googleAccounts.length === 1 &&
    soleGoogle != null &&
    input.keepUserId !== soleGoogle &&
    input.forceDeleteGoogleAccount !== true
  ) {
    throw new DeletionGuardError(
      "failed-precondition",
      "The Google Sign-In account must be kept unless forceDeleteGoogleAccount is true.",
    );
  }

  if (
    googleAccounts.length > 1 &&
    !keepAccount.hasGoogleProvider &&
    deletingGoogle &&
    input.forceDeleteGoogleAccount !== true
  ) {
    throw new DeletionGuardError(
      "failed-precondition",
      "When multiple Google accounts exist, keep one Google account or pass forceDeleteGoogleAccount.",
    );
  }

  return { keepUserId: input.keepUserId, deleteUserIds };
}
