import assert from "node:assert/strict";
import test from "node:test";

import {
  assertMaestroStagingProject,
  assessPasswordLinking,
  buildMaestroAvailabilitySlotId,
  buildVerifyAccountResult,
  findFirestoreUsersByEmail,
  formatAuthAccountReport,
  generateMaestroAvailabilitySlots,
  mergeTeacherWhitelist,
  normalizeEmail,
  wouldCreateDuplicateUser,
  MAESTRO_ACCOUNT_SPECS,
  type GeneratedAvailabilitySlot,
} from "../../src/quranSessions/maestroStagingAccounts";

function fakeAuthUser(params: {
  uid: string;
  email: string;
  providers: string[];
  displayName?: string;
}): import("firebase-admin/auth").UserRecord {
  return {
    uid: params.uid,
    email: params.email,
    emailVerified: true,
    displayName: params.displayName,
    disabled: false,
    metadata: {} as import("firebase-admin/auth").UserMetadata,
    providerData: params.providers.map((providerId) => ({
      providerId,
      uid: params.uid,
      displayName: params.displayName ?? null,
      email: params.email,
      phoneNumber: null,
      photoURL: null,
      toJSON: () => ({}),
    })),
    toJSON: () => ({}),
  } as unknown as import("firebase-admin/auth").UserRecord;
}

test("assertMaestroStagingProject allows quran-playera-app only", () => {
  assert.doesNotThrow(() => assertMaestroStagingProject("quran-playera-app"));
  assert.throws(
    () => assertMaestroStagingProject("tilawa-production"),
    /production project/,
  );
  assert.throws(
    () => assertMaestroStagingProject("other-staging"),
    /expected staging project/,
  );
});

test("assessPasswordLinking confirms google account can receive password on same uid", () => {
  const user = fakeAuthUser({
    uid: "teacher_uid",
    email: "teacher@example.com",
    providers: ["google.com"],
    displayName: "Teacher QA",
  });

  const assessment = assessPasswordLinking(user);
  assert.equal(assessment.canLinkPasswordToSameUid, true);
  assert.equal(assessment.hasGoogleProvider, true);
  assert.equal(assessment.hasPasswordProvider, false);
});

test("buildVerifyAccountResult fails on duplicate Firestore profiles", () => {
  const user = fakeAuthUser({
    uid: "uid_a",
    email: "teacher@example.com",
    providers: ["google.com"],
  });
  const result = buildVerifyAccountResult({
    spec: MAESTRO_ACCOUNT_SPECS[0],
    authUser: user,
    firestoreUserIds: ["uid_a", "uid_b"],
  });

  assert.equal(result.pass, false);
  assert.match(result.errors.join(" "), /Duplicate Firestore profiles/);
});

test("buildVerifyAccountResult passes for matching auth + firestore uid", () => {
  const user = fakeAuthUser({
    uid: "uid_a",
    email: "teacher@example.com",
    providers: ["google.com"],
  });
  const result = buildVerifyAccountResult({
    spec: MAESTRO_ACCOUNT_SPECS[0],
    authUser: user,
    firestoreUserIds: ["uid_a"],
  });

  assert.equal(result.pass, true);
  assert.match(formatAuthAccountReport(result), /PASS/);
});

test("findFirestoreUsersByEmail is case-insensitive", () => {
  const ids = findFirestoreUsersByEmail(
    [
      { id: "uid_a", email: "Teacher@Example.com" },
      { id: "uid_b", email: "other@example.com" },
    ],
    "teacher@example.com",
  );

  assert.deepEqual(ids, ["uid_a"]);
});

test("wouldCreateDuplicateUser detects mismatched firestore uids", () => {
  assert.equal(
    wouldCreateDuplicateUser({ authUid: "uid_a", firestoreUserIds: ["uid_b"] }),
    true,
  );
  assert.equal(
    wouldCreateDuplicateUser({ authUid: "uid_a", firestoreUserIds: ["uid_a"] }),
    false,
  );
});

test("generateMaestroAvailabilitySlots uses deterministic ids", () => {
  const now = new Date("2026-07-06T12:00:00.000Z");
  const slots = generateMaestroAvailabilitySlots({
    teacherId: "teacher1",
    now,
    minDays: 7,
    maxDays: 7,
  });

  assert.ok(slots.length > 0);
  const firstId = buildMaestroAvailabilitySlotId(slots[0].startsAt);
  assert.equal(slots[0].slotId, firstId);

  const again = generateMaestroAvailabilitySlots({
    teacherId: "teacher1",
    now,
    minDays: 7,
    maxDays: 7,
  });
  assert.deepEqual(
    again.map((slot: GeneratedAvailabilitySlot) => slot.slotId),
    slots.map((slot: GeneratedAvailabilitySlot) => slot.slotId),
  );
});

test("mergeTeacherWhitelist is idempotent", () => {
  assert.deepEqual(
    mergeTeacherWhitelist(["teacher_a"], "teacher_b"),
    ["teacher_a", "teacher_b"],
  );
  assert.deepEqual(
    mergeTeacherWhitelist(["teacher_a", "teacher_b"], "teacher_b"),
    ["teacher_a", "teacher_b"],
  );
});

test("normalizeEmail trims and lowercases", () => {
  assert.equal(normalizeEmail("  Foo@Bar.com "), "foo@bar.com");
});
