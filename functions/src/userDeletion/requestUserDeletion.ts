import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";

import {
  AuthGateway,
  AuthGatewayUser,
  adminAuthGateway,
} from "./authGateway";
import {
  ACTIVE_BOOKING_STATUSES,
  PURGE_GRACE_DAYS,
} from "./deletionManifest";
import {
  appendDeletionAuditEvent,
  deletionStateRef,
  hashEmail,
  TeacherVisibilitySnapshot,
} from "./deletionStateService";
import {
  DeletionGuardError,
  assertTargetDeletable,
  computePurgeAfterMs,
  validateRequestUserDeletionInput,
} from "./userDeletionLogic";
import { walletIdForUser } from "../quranSessions/walletService";

export interface RequestUserDeletionResult {
  status: "pending_deletion";
  purgeAfter: string;
  auditId: string;
}

export interface TeacherProfileMatch {
  id: string;
  isActive: boolean;
  isPubliclyVisible: boolean;
}

/**
 * Finds the target's teacher profile. Profiles normally carry a `userId`
 * field; legacy profiles may use the auth uid as the doc id (see
 * teacherProfileUserId.ts), so both lookups run.
 */
export async function findTeacherProfile(
  db: Firestore,
  uid: string,
): Promise<TeacherProfileMatch | null> {
  const byField = await db
    .collection("quran_teacher_profiles")
    .where("userId", "==", uid)
    .limit(1)
    .get();
  const doc = byField.empty
    ? await db.collection("quran_teacher_profiles").doc(uid).get()
    : byField.docs[0];
  if (!("exists" in doc) || !doc.exists) return null;
  const data = doc.data() ?? {};
  return {
    id: doc.id,
    isActive: data.isActive === true,
    isPubliclyVisible: data.isPubliclyVisible === true,
  };
}

export async function assertNoActiveBookings(
  db: Firestore,
  uid: string,
  teacherProfileId: string | null,
): Promise<void> {
  const statuses = [...ACTIVE_BOOKING_STATUSES];
  const asStudent = await db
    .collection("quran_bookings")
    .where("studentId", "==", uid)
    .where("lifecycleStatus", "in", statuses)
    .limit(1)
    .get();
  if (!asStudent.empty) {
    throw new DeletionGuardError(
      "failed-precondition",
      "User has active bookings as a student. Cancel or complete them first.",
    );
  }
  if (teacherProfileId) {
    const asTeacher = await db
      .collection("quran_bookings")
      .where("teacherId", "==", teacherProfileId)
      .where("lifecycleStatus", "in", statuses)
      .limit(1)
      .get();
    if (!asTeacher.empty) {
      throw new DeletionGuardError(
        "failed-precondition",
        "User has active bookings as a teacher. Cancel or complete them first.",
      );
    }
  }
}

export async function assertWalletEmpty(db: Firestore, uid: string): Promise<void> {
  const snap = await db
    .collection("user_wallets")
    .doc(walletIdForUser(uid))
    .get();
  if (!snap.exists) return;
  const data = snap.data() ?? {};
  const available = Number(data.availableBalance ?? 0);
  const held = Number(data.heldBalance ?? 0);
  if (available > 0 || held > 0) {
    throw new DeletionGuardError(
      "failed-precondition",
      `Wallet balance is not zero (available ${available}, held ${held}). ` +
        "Refund or write off the balance first.",
    );
  }
}

export async function deleteFcmTokens(
  db: Firestore,
  uid: string,
): Promise<number> {
  const refs = await db
    .collection("users")
    .doc(uid)
    .collection("fcm_tokens")
    .listDocuments();
  let deleted = 0;
  while (deleted < refs.length) {
    const batch = db.batch();
    for (const ref of refs.slice(deleted, deleted + 400)) {
      batch.delete(ref);
    }
    await batch.commit();
    deleted = Math.min(deleted + 400, refs.length);
  }
  return refs.length;
}

/**
 * Core soft-delete execution shared by admin and self-service callables.
 * Callers must run their own validation guards before invoking this.
 */
async function assertAuthTargetExists(
  db: Firestore,
  auth: AuthGateway,
  targetUserId: string,
): Promise<AuthGatewayUser> {
  const target = await auth.getUser(targetUserId);
  if (target) {
    return target;
  }

  const userSnap = await db.collection("users").doc(targetUserId).get();
  if (userSnap.exists) {
    throw new DeletionGuardError(
      "not-found",
      "This user exists in Firestore but has no Firebase Auth account. " +
        "Use Duplicate Accounts cleanup or manual data purge.",
    );
  }

  throw new DeletionGuardError("not-found", "Target user not found.");
}

export async function executePendingUserDeletion(input: {
  db: Firestore;
  auth: AuthGateway;
  callerUid: string;
  targetUserId: string;
  reason: string;
  nowMs?: number;
  graceDays?: number;
}): Promise<RequestUserDeletionResult> {
  const { db, auth, callerUid, targetUserId, reason } = input;

  const stateSnap = await deletionStateRef(db, targetUserId).get();
  const stateStatus = stateSnap.data()?.status;
  if (stateStatus === "pending_deletion" || stateStatus === "purging") {
    throw new DeletionGuardError(
      "failed-precondition",
      "Deletion is already pending for this user.",
    );
  }
  if (stateStatus === "purged") {
    throw new DeletionGuardError(
      "failed-precondition",
      "User has already been purged.",
    );
  }

  const target = await assertAuthTargetExists(db, auth, targetUserId);

  const teacherProfile = await findTeacherProfile(db, targetUserId);
  await assertWalletEmpty(db, targetUserId);
  await assertNoActiveBookings(db, targetUserId, teacherProfile?.id ?? null);

  // Lock the account out before any bookkeeping: even if a later write
  // fails and the admin retries, the user can no longer sign in.
  await auth.setDisabled(targetUserId, true);
  await auth.revokeRefreshTokens(targetUserId);

  const nowMs = input.nowMs ?? Date.now();
  const purgeAfter = Timestamp.fromMillis(
    computePurgeAfterMs(nowMs, input.graceDays ?? PURGE_GRACE_DAYS),
  );
  const targetEmailHash = target.email ? hashEmail(target.email) : null;

  const userRef = db.collection("users").doc(targetUserId);
  const userSnap = await userRef.get();
  const userData = userSnap.data() ?? {};
  const profileData =
    (userData.quranSessionsProfile as Record<string, unknown> | undefined) ??
    null;

  const priorTeacherVisibility: TeacherVisibilitySnapshot | null =
    teacherProfile
      ? {
          isActive: teacherProfile.isActive,
          isPubliclyVisible: teacherProfile.isPubliclyVisible,
        }
      : null;

  const batch = db.batch();
  batch.set(deletionStateRef(db, targetUserId), {
    userId: targetUserId,
    status: "pending_deletion",
    reason,
    requestedBy: callerUid,
    requestedAt: FieldValue.serverTimestamp(),
    purgeAfter,
    targetEmailHash,
    priorAccountStatus:
      typeof userData.accountStatus === "string"
        ? userData.accountStatus
        : null,
    priorProfileAccountStatus:
      typeof profileData?.accountStatus === "string"
        ? (profileData.accountStatus as string)
        : null,
    priorTeacherVisibility,
    teacherProfileId: teacherProfile?.id ?? null,
    completedSteps: [],
    financialSummary: null,
    purgedAt: null,
    cancelledAt: null,
    cancelledBy: null,
    cancelReason: null,
  });

  const userPatch: Record<string, unknown> = {
    accountStatus: "pending_deletion",
    deletion: {
      requestedAt: FieldValue.serverTimestamp(),
      requestedBy: callerUid,
      reason,
      purgeAfter,
    },
  };
  if (userSnap.exists && profileData) {
    userPatch["quranSessionsProfile.accountStatus"] = "pending_deletion";
    userPatch["quranSessionsProfile.restrictionReason"] = "account_deletion";
    batch.update(userRef, userPatch);
  } else {
    // Auth-only accounts (or missing profile map): set a minimal envelope so
    // the pending state is still visible in the admin panel's users list.
    batch.set(userRef, userPatch, { merge: true });
  }

  if (teacherProfile) {
    batch.update(
      db.collection("quran_teacher_profiles").doc(teacherProfile.id),
      { isActive: false, isPubliclyVisible: false },
    );
  }

  await batch.commit();
  await deleteFcmTokens(db, targetUserId);

  const auditId = await appendDeletionAuditEvent(db, {
    targetUserId,
    action: "requested",
    actorUid: callerUid,
    reason,
    targetEmailHash,
    details: {
      purgeAfter: purgeAfter.toDate().toISOString(),
      teacherProfileId: teacherProfile?.id ?? null,
    },
  });

  console.info("requestUserDeletion", {
    adminUid: callerUid,
    targetUserId,
    purgeAfter: purgeAfter.toDate().toISOString(),
  });

  return {
    status: "pending_deletion",
    purgeAfter: purgeAfter.toDate().toISOString(),
    auditId,
  };
}

/**
 * Core of requestUserDeletion, callable-framework-free so integration tests
 * drive it against the Firestore emulator with a fake AuthGateway.
 */
export async function executeRequestUserDeletion(input: {
  db: Firestore;
  auth: AuthGateway;
  callerUid: string;
  data: unknown;
  nowMs?: number;
  graceDays?: number;
}): Promise<RequestUserDeletionResult> {
  const { db, auth, callerUid } = input;
  const { targetUserId, reason, confirmEmail } =
    validateRequestUserDeletionInput(input.data);

  const target = await assertAuthTargetExists(db, auth, targetUserId);
  assertTargetDeletable({ callerUid, target, confirmEmail });

  return executePendingUserDeletion({
    db,
    auth,
    callerUid,
    targetUserId,
    reason,
    nowMs: input.nowMs,
    graceDays: input.graceDays,
  });
}

export function mapGuardError(error: unknown): never {
  if (error instanceof DeletionGuardError) {
    throw new HttpsError(error.code, error.message);
  }
  throw error;
}

/**
 * Admin-only: soft-deletes a user (Auth lockout + pending_deletion) and
 * schedules the hard purge after the grace period.
 * Requires custom claim `{ admin: true }`.
 */
export const requestUserDeletion = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    try {
      return await executeRequestUserDeletion({
        db: getFirestore(),
        auth: adminAuthGateway(),
        callerUid: request.auth.uid,
        data: request.data,
      });
    } catch (error) {
      mapGuardError(error);
    }
  },
);


