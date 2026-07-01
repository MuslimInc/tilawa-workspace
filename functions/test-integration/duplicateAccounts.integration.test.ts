import test from "node:test";
import assert from "node:assert/strict";

import { clearFirestore, db } from "./support/emulator";
import type {
  AuthGateway,
  AuthGatewayUser,
} from "../src/userDeletion/authGateway";
import type { AuthAccountLookup } from "../src/userDeletion/authAccountLookup";
import {
  GOOGLE_PROVIDER_ID,
  lookupAuthAccountsByEmail,
} from "../src/userDeletion/authAccountLookup";
import { executeRequestDuplicateAccountsDeletion } from "../src/userDeletion/requestDuplicateAccountsDeletion";
import { DeletionGuardError } from "../src/userDeletion/userDeletionLogic";

const EMAIL = "dup@example.com";
const GOOGLE_UID = "google-dup-1";
const PASSWORD_UID = "password-dup-1";
const ADMIN_UID = "admin-dup-1";

interface FakeAuthUser extends AuthGatewayUser {
  revokeCount: number;
  deleted: boolean;
  providerIds: string[];
  creationTime: string;
  lastSignInTime: string;
}

function fakeAuth(users: Map<string, FakeAuthUser>): AuthGateway {
  return {
    async getUser(uid) {
      const user = users.get(uid);
      return user && !user.deleted ? user : null;
    },
    async setDisabled(uid, disabled) {
      const user = users.get(uid);
      if (user) user.disabled = disabled;
    },
    async revokeRefreshTokens(uid) {
      const user = users.get(uid);
      if (user) user.revokeCount += 1;
    },
    async deleteUser(uid) {
      const user = users.get(uid);
      if (user) user.deleted = true;
    },
  };
}

function fakeLookup(users: Map<string, FakeAuthUser>): AuthAccountLookup {
  const toRecord = (user: FakeAuthUser) =>
    ({
      uid: user.uid,
      email: user.email,
      disabled: user.disabled,
      customClaims: user.customClaims,
      providerData: user.providerIds.map((providerId) => ({
        providerId,
        uid: user.uid,
        toJSON() {
          return {};
        },
      })),
      metadata: {
        creationTime: user.creationTime,
        lastSignInTime: user.lastSignInTime,
        lastRefreshTime: null,
        toJSON() {
          return {};
        },
      },
      toJSON() {
        return {};
      },
    }) as never;

  return {
    async findUsersByEmail(email) {
      const normalized = email.trim().toLowerCase();
      const matches = [...users.values()].filter(
        (user) => user.email?.toLowerCase() === normalized && !user.deleted,
      );
      return {
        users: matches.map(toRecord),
        truncated: false,
      };
    },
    async getUserByEmail(email) {
      const normalized = email.trim().toLowerCase();
      const match = [...users.values()].find(
        (user) => user.email?.toLowerCase() === normalized && !user.deleted,
      );
      return match ? toRecord(match) : null;
    },
    async getUser(uid) {
      const user = users.get(uid);
      return user && !user.deleted ? toRecord(user) : null;
    },
  };
}

function seedUsers(): Map<string, FakeAuthUser> {
  return new Map([
    [
      GOOGLE_UID,
      {
        uid: GOOGLE_UID,
        email: EMAIL,
        disabled: false,
        customClaims: {},
        revokeCount: 0,
        deleted: false,
        providerIds: [GOOGLE_PROVIDER_ID],
        creationTime: "2026-01-02T00:00:00.000Z",
        lastSignInTime: "2026-03-01T00:00:00.000Z",
      },
    ],
    [
      PASSWORD_UID,
      {
        uid: PASSWORD_UID,
        email: EMAIL,
        disabled: false,
        customClaims: {},
        revokeCount: 0,
        deleted: false,
        providerIds: ["password"],
        creationTime: "2026-01-01T00:00:00.000Z",
        lastSignInTime: "2026-02-01T00:00:00.000Z",
      },
    ],
    [
      ADMIN_UID,
      {
        uid: ADMIN_UID,
        email: "admin@example.com",
        disabled: false,
        customClaims: { admin: true },
        revokeCount: 0,
        deleted: false,
        providerIds: [GOOGLE_PROVIDER_ID],
        creationTime: "2026-01-01T00:00:00.000Z",
        lastSignInTime: "2026-03-01T00:00:00.000Z",
      },
    ],
  ]);
}

async function seedFirestore() {
  const firestore = db();
  await firestore.collection("users").doc(GOOGLE_UID).set({
    email: EMAIL,
    quranSessionsProfile: { accountStatus: "active", role: "student" },
  });
  await firestore.collection("users").doc(PASSWORD_UID).set({
    email: EMAIL,
    quranSessionsProfile: { accountStatus: "active", role: "student" },
  });
  await firestore
    .collection("users")
    .doc(PASSWORD_UID)
    .collection("fcm_tokens")
    .doc("t1")
    .set({ token: "abc" });
}

test("duplicate lookup returns all accounts for an email", async () => {
  await clearFirestore();
  await seedFirestore();
  const users = seedUsers();

  const result = await lookupAuthAccountsByEmail({
    db: db(),
    lookup: fakeLookup(users),
    email: EMAIL,
  });

  assert.equal(result.accounts.length, 2);
  assert.equal(
    result.accounts.find((item) => item.uid === GOOGLE_UID)?.hasGoogleProvider,
    true,
  );
});

test("duplicate deletion keeps Google and soft-deletes password duplicate", async () => {
  await clearFirestore();
  await seedFirestore();
  const users = seedUsers();
  const auth = fakeAuth(users);

  const result = await executeRequestDuplicateAccountsDeletion({
    auth,
    callerUid: ADMIN_UID,
    lookup: fakeLookup(users),
    data: {
      email: EMAIL,
      reason: "Remove duplicate password account for Google user",
      confirmEmail: EMAIL,
      keepUserId: GOOGLE_UID,
      deleteUserIds: [PASSWORD_UID],
    },
  });

  assert.equal(result.keepUserId, GOOGLE_UID);
  assert.equal(result.results.length, 1);
  assert.equal(result.results[0]?.status, "pending_deletion");

  assert.equal(users.get(PASSWORD_UID)?.disabled, true);
  assert.equal(users.get(GOOGLE_UID)?.disabled, false);

  const firestore = db();
  const passwordDoc = await firestore.collection("users").doc(PASSWORD_UID).get();
  assert.equal(passwordDoc.get("accountStatus"), "pending_deletion");
  const googleDoc = await firestore.collection("users").doc(GOOGLE_UID).get();
  assert.notEqual(googleDoc.get("accountStatus"), "pending_deletion");

  const audits = await firestore
    .collection("user_deletion_audit")
    .where("targetUserId", "==", PASSWORD_UID)
    .get();
  assert.equal(audits.size, 1);
});

test("duplicate deletion is idempotent when retrying the same password duplicate", async () => {
  await clearFirestore();
  await seedFirestore();
  const users = seedUsers();
  const auth = fakeAuth(users);
  const lookup = fakeLookup(users);

  const payload = {
    email: EMAIL,
    reason: "Remove duplicate password account for Google user",
    confirmEmail: EMAIL,
    keepUserId: GOOGLE_UID,
    deleteUserIds: [PASSWORD_UID],
  };

  await executeRequestDuplicateAccountsDeletion({
    auth,
    callerUid: ADMIN_UID,
    lookup,
    data: payload,
  });
  const retry = await executeRequestDuplicateAccountsDeletion({
    auth,
    callerUid: ADMIN_UID,
    lookup,
    data: payload,
  });
  assert.equal(retry.results[0]?.status, "already_pending");
});

test("duplicate deletion rejects unsafe Google deletion by default", async () => {
  await clearFirestore();
  await seedFirestore();
  const users = seedUsers();
  const auth = fakeAuth(users);

  await assert.rejects(
    executeRequestDuplicateAccountsDeletion({
      auth,
      callerUid: ADMIN_UID,
      lookup: fakeLookup(users),
      data: {
        email: EMAIL,
        reason: "Attempt to delete Google account by mistake",
        confirmEmail: EMAIL,
        keepUserId: PASSWORD_UID,
        deleteUserIds: [GOOGLE_UID],
      },
    }),
    DeletionGuardError,
  );
});

test("duplicate lookup includes Firestore-only orphans", async () => {
  await clearFirestore();
  await seedFirestore();
  const users = seedUsers();
  const orphanUid = "firestore-orphan-dup";
  await db().collection("users").doc(orphanUid).set({
    email: EMAIL,
    displayName: "Orphan duplicate",
  });

  const result = await lookupAuthAccountsByEmail({
    db: db(),
    lookup: fakeLookup(users),
    email: EMAIL,
  });

  assert.equal(result.accounts.length, 3);
  const orphan = result.accounts.find((item) => item.uid === orphanUid);
  assert.equal(orphan?.isFirestoreOnly, true);
  assert.equal(orphan?.hasGoogleProvider, false);
});

test("duplicate deletion purges Firestore-only orphans immediately", async () => {
  await clearFirestore();
  await seedFirestore();
  const users = seedUsers();
  const auth = fakeAuth(users);
  const orphanUid = "firestore-orphan-dup";
  await db().collection("users").doc(orphanUid).set({
    email: EMAIL,
    displayName: "Orphan duplicate",
    quranSessionsProfile: { accountStatus: "active", role: "student" },
  });

  const result = await executeRequestDuplicateAccountsDeletion({
    auth,
    callerUid: ADMIN_UID,
    lookup: fakeLookup(users),
    data: {
      email: EMAIL,
      reason: "Remove orphan Firestore duplicate profiles",
      confirmEmail: EMAIL,
      keepUserId: GOOGLE_UID,
      deleteUserIds: [orphanUid],
    },
  });

  assert.equal(result.results.length, 1);
  assert.equal(result.results[0]?.status, "purged");

  const orphanDoc = await db().collection("users").doc(orphanUid).get();
  assert.equal(orphanDoc.exists, false);
});

test("buildKeepGoogleDeletionPlan matches lookup accounts", async () => {
  await clearFirestore();
  await seedFirestore();
  const users = seedUsers();

  const lookup = await lookupAuthAccountsByEmail({
    db: db(),
    lookup: fakeLookup(users),
    email: EMAIL,
  });
  const { buildKeepGoogleDeletionPlan } = await import(
    "../src/userDeletion/duplicateAccountLogic"
  );
  assert.deepEqual(buildKeepGoogleDeletionPlan(lookup.accounts), {
    keepUserId: GOOGLE_UID,
    deleteUserIds: [PASSWORD_UID],
  });
});

