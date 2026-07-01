import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  Firestore,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";

import { AuthGateway, adminAuthGateway } from "./authGateway";
import {
  appendDeletionAuditEvent,
  deletionStateRef,
  hashEmail,
  TeacherVisibilitySnapshot,
} from "./deletionStateService";
import { purgeUser } from "./purgeUserData";
import {
  assertNoActiveBookings,
  assertWalletEmpty,
  findTeacherProfile,
  mapGuardError,
} from "./requestUserDeletion";
import {
  DeletionGuardError,
  MIN_REASON_LENGTH,
  MAX_REASON_LENGTH,
} from "./userDeletionLogic";

export interface PurgeFirestoreOrphanResult {
  status: "purged";
  auditId: string;
}

function validatePurgeFirestoreOrphanInput(data: unknown): {
  targetUserId: string;
  reason: string;
} {
  const record = (data ?? {}) as Record<string, unknown>;
  const targetUserId =
    typeof record.targetUserId === "string" ? record.targetUserId.trim() : "";
  if (!targetUserId) {
    throw new DeletionGuardError("invalid-argument", "targetUserId required.");
  }
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
  return { targetUserId, reason };
}

/**
 * Immediately purges a Firestore-only user profile (no Firebase Auth account)
 * using the standard deletion manifest, skipping the auth_user step.
 */
export async function executePurgeFirestoreOrphanUser(input: {
  db: Firestore;
  auth: AuthGateway;
  callerUid: string;
  targetUserId: string;
  reason: string;
}): Promise<PurgeFirestoreOrphanResult> {
  const { db, auth, callerUid, targetUserId, reason } = input;

  const authUser = await auth.getUser(targetUserId);
  if (authUser) {
    throw new DeletionGuardError(
      "failed-precondition",
      "Target user has a Firebase Auth account; use requestUserDeletion instead.",
    );
  }

  const userRef = db.collection("users").doc(targetUserId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new DeletionGuardError("not-found", "Target user not found.");
  }

  const stateRef = deletionStateRef(db, targetUserId);
  const stateSnap = await stateRef.get();
  const stateStatus = stateSnap.data()?.status;
  if (stateStatus === "purged") {
    throw new DeletionGuardError(
      "failed-precondition",
      "User has already been purged.",
    );
  }
  if (stateStatus === "pending_deletion" || stateStatus === "purging") {
    const result = await purgeUser({ db, auth, uid: targetUserId, actorUid: callerUid });
    if (result.status !== "purged") {
      throw new DeletionGuardError(
        "failed-precondition",
        "Deletion is already in progress for this user.",
      );
    }
    const auditId = await appendDeletionAuditEvent(db, {
      targetUserId,
      action: "purged",
      actorUid: callerUid,
      reason,
      details: { firestoreOnly: true, resumed: true },
    });
    return { status: "purged", auditId };
  }

  const userData = userSnap.data() ?? {};
  const profileData =
    (userData.quranSessionsProfile as Record<string, unknown> | undefined) ??
    null;
  const teacherProfile = await findTeacherProfile(db, targetUserId);
  await assertWalletEmpty(db, targetUserId);
  await assertNoActiveBookings(db, targetUserId, teacherProfile?.id ?? null);

  const email =
    typeof userData.email === "string" ? userData.email.trim() : "";
  const targetEmailHash = email ? hashEmail(email) : null;
  const priorTeacherVisibility: TeacherVisibilitySnapshot | null =
    teacherProfile != null
      ? {
          isActive: teacherProfile.isActive,
          isPubliclyVisible: teacherProfile.isPubliclyVisible,
        }
      : null;

  const now = Timestamp.now();
  await stateRef.set({
    userId: targetUserId,
    status: "purging",
    reason,
    requestedBy: callerUid,
    requestedAt: now,
    purgeAfter: now,
    targetEmailHash,
    priorAccountStatus:
      typeof userData.accountStatus === "string" ? userData.accountStatus : null,
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
    firestoreOnly: true,
  });

  if (teacherProfile) {
    await db.collection("quran_teacher_profiles").doc(teacherProfile.id).update({
      isActive: false,
      isPubliclyVisible: false,
    });
  }

  await appendDeletionAuditEvent(db, {
    targetUserId,
    action: "requested",
    actorUid: callerUid,
    reason,
    targetEmailHash,
    details: { firestoreOnly: true, immediatePurge: true },
  });

  const result = await purgeUser({
    db,
    auth,
    uid: targetUserId,
    actorUid: callerUid,
  });
  if (result.status !== "purged") {
    throw new DeletionGuardError(
      "failed-precondition",
      "Firestore orphan purge did not complete.",
    );
  }

  const auditId = await appendDeletionAuditEvent(db, {
    targetUserId,
    action: "purged",
    actorUid: callerUid,
    reason,
    targetEmailHash,
    details: { firestoreOnly: true, stepsRun: result.stepsRun },
  });

  console.info("purgeFirestoreOrphanUser", {
    adminUid: callerUid,
    targetUserId,
    stepsRun: result.stepsRun,
  });

  return { status: "purged", auditId };
}

/**
 * Admin-only: hard-purges a Firestore user doc that has no Firebase Auth
 * account. Requires custom claim `{ admin: true }`.
 */
export const purgeFirestoreOrphanUser = onCall(
  { enforceAppCheck: false, timeoutSeconds: 540 },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    try {
      const parsed = validatePurgeFirestoreOrphanInput(request.data);
      return await executePurgeFirestoreOrphanUser({
        db: getFirestore(),
        auth: adminAuthGateway(),
        callerUid: request.auth.uid,
        targetUserId: parsed.targetUserId,
        reason: parsed.reason,
      });
    } catch (error) {
      mapGuardError(error);
    }
  },
);
