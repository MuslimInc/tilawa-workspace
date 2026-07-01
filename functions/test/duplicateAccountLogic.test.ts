import test from "node:test";
import assert from "node:assert/strict";

import { AuthAccountSummary } from "../src/userDeletion/authAccountLookup";
import {
  buildKeepGoogleDeletionPlan,
  validateDuplicateDeletionPlan,
  validateDuplicateDeletionRequestInput,
} from "../src/userDeletion/duplicateAccountLogic";
import { DeletionGuardError } from "../src/userDeletion/userDeletionLogic";

function account(
  partial: Partial<AuthAccountSummary> & Pick<AuthAccountSummary, "uid">,
): AuthAccountSummary {
  return {
    uid: partial.uid,
    email: partial.email ?? "user@example.com",
    disabled: partial.disabled ?? false,
    customClaims: partial.customClaims ?? {},
    providerIds: partial.providerIds ?? [],
    hasGoogleProvider: partial.hasGoogleProvider ?? false,
    creationTime: partial.creationTime ?? null,
    lastSignInTime: partial.lastSignInTime ?? null,
    firestoreAccountStatus: partial.firestoreAccountStatus ?? null,
    firestoreProfileStatus: partial.firestoreProfileStatus ?? null,
    firestoreHasUserDoc: partial.firestoreHasUserDoc ?? true,
    deletionStateStatus: partial.deletionStateStatus ?? null,
    isFirestoreOnly: partial.isFirestoreOnly ?? false,
  };
}

function guardCode(fn: () => void): string {
  try {
    fn();
  } catch (error) {
    if (error instanceof DeletionGuardError) return error.code;
    throw error;
  }
  return "none";
}

const EMAIL = "user@example.com";

test("buildKeepGoogleDeletionPlan returns null for a single account", () => {
  assert.equal(
    buildKeepGoogleDeletionPlan([account({ uid: "u1", hasGoogleProvider: true })]),
    null,
  );
});

test("buildKeepGoogleDeletionPlan keeps the sole Google account", () => {
  const plan = buildKeepGoogleDeletionPlan([
    account({ uid: "google-1", hasGoogleProvider: true, providerIds: ["google.com"] }),
    account({ uid: "password-1", providerIds: ["password"] }),
  ]);
  assert.deepEqual(plan, {
    keepUserId: "google-1",
    deleteUserIds: ["password-1"],
  });
});

test("buildKeepGoogleDeletionPlan returns null when multiple Google accounts exist", () => {
  assert.equal(
    buildKeepGoogleDeletionPlan([
      account({ uid: "g1", hasGoogleProvider: true }),
      account({ uid: "g2", hasGoogleProvider: true }),
    ]),
    null,
  );
});

test("validateDuplicateDeletionPlan rejects deleting the Google account by default", () => {
  const accounts = [
    account({ uid: "google-1", hasGoogleProvider: true }),
    account({ uid: "password-1" }),
  ];
  assert.equal(
    guardCode(() =>
      validateDuplicateDeletionPlan({
        callerUid: "admin-1",
        accounts,
        keepUserId: "password-1",
        deleteUserIds: ["google-1"],
      }),
    ),
    "failed-precondition",
  );
});

test("validateDuplicateDeletionPlan keeps Google and deletes non-Google duplicates", () => {
  const plan = validateDuplicateDeletionPlan({
    callerUid: "admin-1",
    accounts: [
      account({ uid: "google-1", hasGoogleProvider: true }),
      account({ uid: "password-1" }),
      account({ uid: "password-2" }),
    ],
    keepUserId: "google-1",
    deleteUserIds: ["password-1", "password-2"],
  });
  assert.deepEqual(plan, {
    keepUserId: "google-1",
    deleteUserIds: ["password-1", "password-2"],
  });
});

test("validateDuplicateDeletionPlan rejects admin targets and self-deletion", () => {
  const accounts = [
    account({ uid: "google-1", hasGoogleProvider: true }),
    account({ uid: "admin-target", customClaims: { admin: true } }),
  ];
  assert.equal(
    guardCode(() =>
      validateDuplicateDeletionPlan({
        callerUid: "admin-1",
        accounts,
        keepUserId: "google-1",
        deleteUserIds: ["admin-target"],
      }),
    ),
    "failed-precondition",
  );
  assert.equal(
    guardCode(() =>
      validateDuplicateDeletionPlan({
        callerUid: "admin-1",
        accounts: [
          account({ uid: "google-1", hasGoogleProvider: true }),
          account({ uid: "admin-1" }),
        ],
        keepUserId: "google-1",
        deleteUserIds: ["admin-1"],
      }),
    ),
    "failed-precondition",
  );
});

test("validateDuplicateDeletionPlan allows manual selection when multiple Google accounts exist", () => {
  const plan = validateDuplicateDeletionPlan({
    callerUid: "admin-1",
    accounts: [
      account({ uid: "g1", hasGoogleProvider: true }),
      account({ uid: "g2", hasGoogleProvider: true }),
      account({ uid: "password-1" }),
    ],
    keepUserId: "g1",
    deleteUserIds: ["g2", "password-1"],
    forceDeleteGoogleAccount: true,
  });
  assert.deepEqual(plan.deleteUserIds, ["g2", "password-1"]);
});

test("validateDuplicateDeletionPlan rejects multiple Google without force when deleting Google", () => {
  assert.equal(
    guardCode(() =>
      validateDuplicateDeletionPlan({
        callerUid: "admin-1",
        accounts: [
          account({ uid: "g1", hasGoogleProvider: true }),
          account({ uid: "g2", hasGoogleProvider: true }),
        ],
        keepUserId: "g1",
        deleteUserIds: ["g2"],
      }),
    ),
    "failed-precondition",
  );
});

test("validateDuplicateDeletionPlan rejects unsafe auto-delete when multiple Google accounts exist", () => {
  assert.equal(
    guardCode(() =>
      validateDuplicateDeletionPlan({
        callerUid: "admin-1",
        accounts: [
          account({ uid: "g1", hasGoogleProvider: true }),
          account({ uid: "g2", hasGoogleProvider: true }),
        ],
        keepUserId: "g1",
        deleteUserIds: ["g2"],
        forceDeleteGoogleAccount: true,
      }),
    ),
    "none",
  );
});

test("validateDuplicateDeletionRequestInput requires email confirmation", () => {
  assert.throws(
    () =>
      validateDuplicateDeletionRequestInput({
        email: EMAIL,
        reason: "Duplicate cleanup requested by support",
        confirmEmail: "wrong@example.com",
        keepUserId: "google-1",
        deleteUserIds: ["password-1"],
      }),
    DeletionGuardError,
  );
  const parsed = validateDuplicateDeletionRequestInput({
    email: EMAIL,
    reason: "Duplicate cleanup requested by support",
    confirmEmail: EMAIL,
    keepUserId: "google-1",
    deleteUserIds: ["password-1"],
  });
  assert.equal(parsed.email, EMAIL);
});

