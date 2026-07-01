import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  FieldValue,
  Firestore,
  getFirestore,
} from "firebase-admin/firestore";

import { AuthGateway, adminAuthGateway } from "./authGateway";
import {
  appendDeletionAuditEvent,
  deletionStateRef,
  DeletionStateDoc,
} from "./deletionStateService";
import {
  DeletionGuardError,
  validateCancelUserDeletionInput,
} from "./userDeletionLogic";
import { mapGuardError } from "./requestUserDeletion";

export interface CancelUserDeletionResult {
  status: "cancelled";
  auditId: string;
}

/** Core of cancelUserDeletion; see executeRequestUserDeletion for the split. */
export async function executeCancelUserDeletion(input: {
  db: Firestore;
  auth: AuthGateway;
  callerUid: string;
  data: unknown;
}): Promise<CancelUserDeletionResult> {
  const { db, auth, callerUid } = input;
  const { targetUserId, reason } = validateCancelUserDeletionInput(input.data);

  const stateRef = deletionStateRef(db, targetUserId);
  const stateSnap = await stateRef.get();
  if (!stateSnap.exists) {
    throw new DeletionGuardError(
      "not-found",
      "No deletion is pending for this user.",
    );
  }
  const state = stateSnap.data() as DeletionStateDoc;
  if (state.status === "purging" || state.status === "purged") {
    throw new DeletionGuardError(
      "failed-precondition",
      `Purge has already ${state.status === "purged" ? "completed" : "started"}; cancellation is no longer possible.`,
    );
  }
  if (state.status !== "pending_deletion") {
    throw new DeletionGuardError(
      "failed-precondition",
      "Deletion is not pending for this user.",
    );
  }

  await auth.setDisabled(targetUserId, false);

  const batch = db.batch();
  batch.update(stateRef, {
    status: "cancelled",
    cancelledAt: FieldValue.serverTimestamp(),
    cancelledBy: callerUid,
    cancelReason: reason,
  });

  const userRef = db.collection("users").doc(targetUserId);
  const userSnap = await userRef.get();
  if (userSnap.exists) {
    const userPatch: Record<string, unknown> = {
      deletion: FieldValue.delete(),
    };
    if (state.priorAccountStatus === null) {
      userPatch.accountStatus = FieldValue.delete();
    } else {
      userPatch.accountStatus = state.priorAccountStatus;
    }
    const hasProfile =
      userSnap.data()?.quranSessionsProfile !== undefined;
    if (hasProfile) {
      userPatch["quranSessionsProfile.accountStatus"] =
        state.priorProfileAccountStatus ?? "active";
      userPatch["quranSessionsProfile.restrictionReason"] =
        FieldValue.delete();
    }
    batch.update(userRef, userPatch);
  }

  if (state.teacherProfileId && state.priorTeacherVisibility) {
    batch.update(
      db.collection("quran_teacher_profiles").doc(state.teacherProfileId),
      {
        isActive: state.priorTeacherVisibility.isActive,
        isPubliclyVisible: state.priorTeacherVisibility.isPubliclyVisible,
      },
    );
  }

  await batch.commit();

  const auditId = await appendDeletionAuditEvent(db, {
    targetUserId,
    action: "cancelled",
    actorUid: callerUid,
    reason,
    targetEmailHash: state.targetEmailHash,
  });

  console.info("cancelUserDeletion", {
    adminUid: callerUid,
    targetUserId,
  });

  // FCM tokens are not restorable; the app re-registers on next sign-in
  // (registerActiveDevice).
  return { status: "cancelled", auditId };
}

/**
 * Admin-only: cancels a pending deletion during the grace period, re-enables
 * the Auth account, and restores prior status/visibility.
 * Requires custom claim `{ admin: true }`.
 */
export const cancelUserDeletion = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    try {
      return await executeCancelUserDeletion({
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
