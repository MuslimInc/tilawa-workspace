import test from "node:test";
import assert from "node:assert/strict";

import { clearFirestore, db } from "./support/emulator";
import type {
  AuthGateway,
  AuthGatewayUser,
} from "../src/userDeletion/authGateway";
import {
  ANONYMIZED_PLACEHOLDER,
  PURGE_STEPS,
} from "../src/userDeletion/deletionManifest";
import { executeCancelUserDeletion } from "../src/userDeletion/cancelUserDeletion";
import { executeRequestUserDeletion } from "../src/userDeletion/requestUserDeletion";
import { executeRequestSelfAccountDeletion } from "../src/userDeletion/requestSelfAccountDeletion";
import { purgeUser, PurgeBlockedError } from "../src/userDeletion/purgeUserData";
import { DeletionGuardError } from "../src/userDeletion/userDeletionLogic";

const ADMIN_UID = "admin-1";
const TARGET_UID = "target-1";
const OTHER_UID = "other-1";
const TEACHER_PROFILE_ID = "teacher-profile-1";
const TARGET_EMAIL = "target@example.com";

interface FakeAuthUser extends AuthGatewayUser {
  revokeCount: number;
  deleted: boolean;
}

/** In-memory AuthGateway: test:integration runs no Auth emulator. */
function fakeAuth(): AuthGateway & { users: Map<string, FakeAuthUser> } {
  const users = new Map<string, FakeAuthUser>([
    [
      TARGET_UID,
      {
        uid: TARGET_UID,
        email: TARGET_EMAIL,
        disabled: false,
        customClaims: {},
        revokeCount: 0,
        deleted: false,
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
      },
    ],
  ]);
  return {
    users,
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

const REQUEST_DATA = {
  targetUserId: TARGET_UID,
  reason: "GDPR erasure request, support ticket 987",
  confirmEmail: TARGET_EMAIL,
};

const SELF_REQUEST_DATA = {
  reason: "Self-service account deletion from mobile app",
  confirmEmail: TARGET_EMAIL,
};

async function seedTarget(options?: { walletBalance?: number }) {
  const firestore = db();
  const userRef = firestore.collection("users").doc(TARGET_UID);
  await userRef.set({
    displayName: "Target User",
    quranSessionsProfile: { accountStatus: "active", role: "teacher" },
  });
  await userRef.collection("fcm_tokens").doc("token-1").set({ token: "t1" });
  await userRef
    .collection("favorites")
    .doc("surahs")
    .collection("items")
    .doc("fav-1")
    .set({ surah: 1 });
  await userRef.collection("purchases").doc("p1").set({ product: "support" });
  await firestore
    .collection("user_wallets")
    .doc(`wallet_${TARGET_UID}`)
    .set({
      userId: TARGET_UID,
      availableBalance: options?.walletBalance ?? 0,
      heldBalance: 0,
    });
  await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER_PROFILE_ID)
    .set({
      userId: TARGET_UID,
      displayName: "Sheikh Target",
      avatarUrl: "https://example.com/a.png",
      publicBio: "Bio text",
      isActive: true,
      isPubliclyVisible: true,
    });
}

async function requestDeletion(auth: ReturnType<typeof fakeAuth>) {
  return executeRequestUserDeletion({
    db: db(),
    auth,
    callerUid: ADMIN_UID,
    data: REQUEST_DATA,
  });
}

async function guardCode(fn: () => Promise<unknown>): Promise<string> {
  try {
    await fn();
  } catch (error) {
    if (error instanceof DeletionGuardError) return error.code;
    throw error;
  }
  return "none";
}

test("requestUserDeletion locks out, flags, and audits the target", async () => {
  await clearFirestore();
  await seedTarget();
  const auth = fakeAuth();

  const result = await requestDeletion(auth);
  assert.equal(result.status, "pending_deletion");

  const target = auth.users.get(TARGET_UID)!;
  assert.equal(target.disabled, true);
  assert.equal(target.revokeCount, 1);

  const firestore = db();
  const userDoc = await firestore.collection("users").doc(TARGET_UID).get();
  assert.equal(userDoc.get("accountStatus"), "pending_deletion");
  assert.equal(
    userDoc.get("quranSessionsProfile.accountStatus"),
    "pending_deletion",
  );
  assert.equal(userDoc.get("deletion.requestedBy"), ADMIN_UID);

  const tokens = await firestore
    .collection("users")
    .doc(TARGET_UID)
    .collection("fcm_tokens")
    .get();
  assert.equal(tokens.size, 0);

  const state = await firestore
    .collection("user_deletion_state")
    .doc(TARGET_UID)
    .get();
  assert.equal(state.get("status"), "pending_deletion");
  assert.equal(state.get("teacherProfileId"), TEACHER_PROFILE_ID);
  assert.deepEqual(state.get("priorTeacherVisibility"), {
    isActive: true,
    isPubliclyVisible: true,
  });
  const purgeAfterMs = state.get("purgeAfter").toMillis();
  const days = (purgeAfterMs - Date.now()) / (24 * 60 * 60 * 1000);
  assert.ok(days > 29 && days < 31, `purgeAfter ${days} days out`);

  const profile = await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER_PROFILE_ID)
    .get();
  assert.equal(profile.get("isActive"), false);
  assert.equal(profile.get("isPubliclyVisible"), false);

  const audit = await firestore
    .collection("user_deletion_audit")
    .where("targetUserId", "==", TARGET_UID)
    .get();
  assert.equal(audit.size, 1);
  assert.equal(audit.docs[0].get("action"), "requested");
});

test("requestUserDeletion guards: wallet, bookings, repeat, admin, self", async () => {
  await clearFirestore();
  await seedTarget({ walletBalance: 50 });
  const auth = fakeAuth();

  assert.equal(await guardCode(() => requestDeletion(auth)), "failed-precondition");

  // Zero the wallet, add an active booking instead.
  const firestore = db();
  await firestore
    .collection("user_wallets")
    .doc(`wallet_${TARGET_UID}`)
    .update({ availableBalance: 0 });
  await firestore.collection("quran_bookings").doc("b1").set({
    studentId: TARGET_UID,
    teacherId: "someone-else",
    lifecycleStatus: "confirmed",
  });
  assert.equal(await guardCode(() => requestDeletion(auth)), "failed-precondition");

  await firestore
    .collection("quran_bookings")
    .doc("b1")
    .update({ lifecycleStatus: "completed" });
  assert.equal(await guardCode(() => requestDeletion(auth)), "none");

  // Second request while pending.
  assert.equal(await guardCode(() => requestDeletion(auth)), "failed-precondition");

  // Self and admin-target guards.
  assert.equal(
    await guardCode(() =>
      executeRequestUserDeletion({
        db: firestore,
        auth,
        callerUid: ADMIN_UID,
        data: {
          ...REQUEST_DATA,
          targetUserId: ADMIN_UID,
          confirmEmail: "admin@example.com",
        },
      }),
    ),
    "failed-precondition",
  );
});

test("requestSelfAccountDeletion locks out the caller", async () => {
  await clearFirestore();
  await seedTarget();
  const auth = fakeAuth();

  const result = await executeRequestSelfAccountDeletion({
    db: db(),
    auth,
    callerUid: TARGET_UID,
    data: SELF_REQUEST_DATA,
  });
  assert.equal(result.status, "pending_deletion");

  const target = auth.users.get(TARGET_UID)!;
  assert.equal(target.disabled, true);
  assert.equal(target.revokeCount, 1);

  const firestore = db();
  const userDoc = await firestore.collection("users").doc(TARGET_UID).get();
  assert.equal(userDoc.get("accountStatus"), "pending_deletion");
  assert.equal(userDoc.get("deletion.requestedBy"), TARGET_UID);
});

test("requestSelfAccountDeletion guards admin accounts", async () => {
  await clearFirestore();
  const auth = fakeAuth();

  assert.equal(
    await guardCode(() =>
      executeRequestSelfAccountDeletion({
        db: db(),
        auth,
        callerUid: ADMIN_UID,
        data: {
          reason: "Self-service account deletion from mobile app",
          confirmEmail: "admin@example.com",
        },
      }),
    ),
    "failed-precondition",
  );
});

test("cancelUserDeletion restores auth and prior state", async () => {
  await clearFirestore();
  await seedTarget();
  const auth = fakeAuth();
  await requestDeletion(auth);

  const result = await executeCancelUserDeletion({
    db: db(),
    auth,
    callerUid: ADMIN_UID,
    data: { targetUserId: TARGET_UID, reason: "Requested in error by admin" },
  });
  assert.equal(result.status, "cancelled");

  const target = auth.users.get(TARGET_UID)!;
  assert.equal(target.disabled, false);
  assert.equal(target.deleted, false);

  const firestore = db();
  const userDoc = await firestore.collection("users").doc(TARGET_UID).get();
  assert.equal(userDoc.get("accountStatus"), undefined);
  assert.equal(userDoc.get("deletion"), undefined);
  assert.equal(userDoc.get("quranSessionsProfile.accountStatus"), "active");

  const profile = await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER_PROFILE_ID)
    .get();
  assert.equal(profile.get("isActive"), true);
  assert.equal(profile.get("isPubliclyVisible"), true);

  const state = await firestore
    .collection("user_deletion_state")
    .doc(TARGET_UID)
    .get();
  assert.equal(state.get("status"), "cancelled");

  // Purge skips cancelled users entirely.
  const purge = await purgeUser({
    db: firestore,
    auth,
    uid: TARGET_UID,
    actorUid: "system",
  });
  assert.equal(purge.status, "skipped");
});

async function seedSharedAndRetainedData() {
  const firestore = db();
  await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER_PROFILE_ID)
    .collection("availability")
    .doc("slot-1")
    .set({ isBooked: false });
  await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER_PROFILE_ID)
    .collection("pricing")
    .doc("EG")
    .set({ price: 100 });
  await firestore.collection("quran_teacher_applications").doc("app-1").set({
    userId: TARGET_UID,
    idDocumentUrl: "https://example.com/id.png",
  });
  await firestore.collection("quran_bookings").doc("booking-1").set({
    studentId: OTHER_UID,
    teacherId: TEACHER_PROFILE_ID,
    lifecycleStatus: "completed",
    amount: 100,
  });
  await firestore.collection("quran_session_reports").doc("report-1").set({
    reporterUserId: OTHER_UID,
    reportedUserId: TARGET_UID,
    details: "abuse evidence",
  });
  await firestore.collection("wallet_transactions").doc("txn-1").set({
    userId: TARGET_UID,
    amount: 100,
    direction: "credit",
  });
  await firestore.collection("notifications").doc("campaign-1").set({
    title: "Campaign",
    targetUserIds: [TARGET_UID, OTHER_UID],
  });
  await firestore
    .collection("quran_session_notifications")
    .doc("outbox-solo")
    .set({ recipientUserIds: [TARGET_UID] });
  await firestore
    .collection("quran_session_notifications")
    .doc("outbox-shared")
    .set({ recipientUserIds: [TARGET_UID, OTHER_UID] });
  await firestore.collection("quran_reschedule_requests").doc("resched-1").set({
    requestedByUserId: TARGET_UID,
    bookingId: "booking-1",
    reason: "private free text",
  });
  await firestore
    .collection("quran_student_metrics")
    .doc(TARGET_UID)
    .set({ sessions: 3 });
  await firestore
    .collection("quran_teacher_metrics")
    .doc(TEACHER_PROFILE_ID)
    .set({ sessions: 9 });
}

test("purgeUser executes the manifest and deletes auth last", async () => {
  await clearFirestore();
  await seedTarget();
  await seedSharedAndRetainedData();
  const auth = fakeAuth();
  await requestDeletion(auth);

  const firestore = db();
  const result = await purgeUser({
    db: firestore,
    auth,
    uid: TARGET_UID,
    actorUid: "system",
  });
  assert.equal(result.status, "purged");

  // Owned data gone.
  assert.equal(
    (await firestore.collection("users").doc(TARGET_UID).get()).exists,
    false,
  );
  const favItems = await firestore
    .collection("users")
    .doc(TARGET_UID)
    .collection("favorites")
    .doc("surahs")
    .collection("items")
    .get();
  assert.equal(favItems.size, 0);
  assert.equal(
    (
      await firestore
        .collection("quran_teacher_applications")
        .doc("app-1")
        .get()
    ).exists,
    false,
  );
  assert.equal(
    (
      await firestore
        .collection("user_wallets")
        .doc(`wallet_${TARGET_UID}`)
        .get()
    ).exists,
    false,
  );
  assert.equal(
    (await firestore.collection("quran_student_metrics").doc(TARGET_UID).get())
      .exists,
    false,
  );

  // Teacher profile anonymized, not deleted; subcollections purged.
  const profile = await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER_PROFILE_ID)
    .get();
  assert.equal(profile.exists, true);
  assert.equal(profile.get("displayName"), ANONYMIZED_PLACEHOLDER);
  assert.equal(profile.get("avatarUrl"), undefined);
  assert.equal(profile.get("publicBio"), undefined);
  assert.equal(profile.get("isDeleted"), true);
  assert.equal(profile.get("userId"), TARGET_UID);
  const availability = await profile.ref.collection("availability").get();
  const pricing = await profile.ref.collection("pricing").get();
  assert.equal(availability.size + pricing.size, 0);

  // Shared + retained data intact.
  const booking = await firestore
    .collection("quran_bookings")
    .doc("booking-1")
    .get();
  assert.equal(booking.get("teacherId"), TEACHER_PROFILE_ID);
  assert.equal(booking.get("amount"), 100);
  const report = await firestore
    .collection("quran_session_reports")
    .doc("report-1")
    .get();
  assert.equal(report.get("reportedUserId"), TARGET_UID);
  assert.equal(report.get("details"), "abuse evidence");
  const txn = await firestore
    .collection("wallet_transactions")
    .doc("txn-1")
    .get();
  assert.equal(txn.get("userId"), TARGET_UID);

  // Anonymized in place.
  const campaign = await firestore
    .collection("notifications")
    .doc("campaign-1")
    .get();
  assert.deepEqual(campaign.get("targetUserIds"), [OTHER_UID]);
  assert.equal(
    (
      await firestore
        .collection("quran_session_notifications")
        .doc("outbox-solo")
        .get()
    ).exists,
    false,
  );
  const outboxShared = await firestore
    .collection("quran_session_notifications")
    .doc("outbox-shared")
    .get();
  assert.deepEqual(outboxShared.get("recipientUserIds"), [OTHER_UID]);
  const resched = await firestore
    .collection("quran_reschedule_requests")
    .doc("resched-1")
    .get();
  assert.equal(resched.get("reason"), ANONYMIZED_PLACEHOLDER);
  assert.equal(resched.get("bookingId"), "booking-1");

  // Auth deleted, state finalized with the financial summary captured
  // before the owned tree was removed.
  assert.equal(auth.users.get(TARGET_UID)!.deleted, true);
  const state = await firestore
    .collection("user_deletion_state")
    .doc(TARGET_UID)
    .get();
  assert.equal(state.get("status"), "purged");
  assert.deepEqual([...state.get("completedSteps")].sort(), [...PURGE_STEPS].sort());
  assert.equal(state.get("financialSummary.purchaseCount"), 1);

  const auditActions = (
    await firestore
      .collection("user_deletion_audit")
      .where("targetUserId", "==", TARGET_UID)
      .get()
  ).docs
    .map((doc) => doc.get("action"))
    .sort();
  assert.deepEqual(auditActions, ["purge_started", "purged", "requested"]);
});

test("purgeUser is idempotent and honors step checkpoints", async () => {
  await clearFirestore();
  await seedTarget();
  const auth = fakeAuth();
  await requestDeletion(auth);
  const firestore = db();

  // Simulate a prior run that already checkpointed owned_tree: the step must
  // be skipped, leaving the (still present) users doc alone.
  await firestore.collection("user_deletion_state").doc(TARGET_UID).update({
    status: "purging",
    completedSteps: ["owned_tree"],
  });
  const resumed = await purgeUser({
    db: firestore,
    auth,
    uid: TARGET_UID,
    actorUid: "system",
  });
  assert.equal(resumed.status, "purged");
  assert.ok(!resumed.stepsRun.includes("owned_tree"));
  assert.equal(
    (await firestore.collection("users").doc(TARGET_UID).get()).exists,
    true,
  );

  // Re-running a purged user is a no-op.
  const again = await purgeUser({
    db: firestore,
    auth,
    uid: TARGET_UID,
    actorUid: "system",
  });
  assert.equal(again.status, "skipped");
  assert.deepEqual(again.stepsRun, []);
});

test("purgeUser blocks on nonzero wallet and keeps the auth user", async () => {
  await clearFirestore();
  await seedTarget();
  const auth = fakeAuth();
  await requestDeletion(auth);
  const firestore = db();

  // Refund credited during the grace period.
  await firestore
    .collection("user_wallets")
    .doc(`wallet_${TARGET_UID}`)
    .set({ userId: TARGET_UID, availableBalance: 25, heldBalance: 0 });

  await assert.rejects(
    purgeUser({ db: firestore, auth, uid: TARGET_UID, actorUid: "system" }),
    PurgeBlockedError,
  );
  // Auth deletion is last: a blocked purge must leave the account.
  assert.equal(auth.users.get(TARGET_UID)!.deleted, false);
  const state = await firestore
    .collection("user_deletion_state")
    .doc(TARGET_UID)
    .get();
  assert.equal(state.get("status"), "purging");
  const failures = await firestore
    .collection("user_deletion_audit")
    .where("targetUserId", "==", TARGET_UID)
    .where("action", "==", "purge_failed")
    .get();
  assert.equal(failures.size, 1);

  // Admin writes off the balance; the retry resumes from the checkpoint.
  await firestore
    .collection("user_wallets")
    .doc(`wallet_${TARGET_UID}`)
    .update({ availableBalance: 0 });
  const retry = await purgeUser({
    db: firestore,
    auth,
    uid: TARGET_UID,
    actorUid: "system",
  });
  assert.equal(retry.status, "purged");
  assert.equal(auth.users.get(TARGET_UID)!.deleted, true);
});

test("requestUserDeletion reports firestore-only orphan distinctly", async () => {
  await clearFirestore();
  const auth = fakeAuth();
  const orphanUid = "orphan-firestore-only";
  await db().collection("users").doc(orphanUid).set({
    email: "orphan@example.com",
    displayName: "Orphan User",
  });

  await assert.rejects(
    () =>
      executeRequestUserDeletion({
        db: db(),
        auth,
        callerUid: ADMIN_UID,
        data: {
          targetUserId: orphanUid,
          reason: "Cleanup orphan firestore profile from duplicate merge",
          confirmEmail: "DELETE",
        },
      }),
    (error: unknown) => {
      assert.ok(error instanceof DeletionGuardError);
      assert.equal(error.code, "not-found");
      assert.match(
        error.message,
        /Firestore but has no Firebase Auth account/,
      );
      return true;
    },
  );
});


