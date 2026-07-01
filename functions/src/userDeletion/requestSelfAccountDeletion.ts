import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Firestore, getFirestore } from "firebase-admin/firestore";

import { AuthGateway, adminAuthGateway } from "./authGateway";
import {
  DeletionGuardError,
  assertSelfDeletable,
  validateSelfAccountDeletionInput,
} from "./userDeletionLogic";
import {
  RequestUserDeletionResult,
  executePendingUserDeletion,
  mapGuardError,
} from "./requestUserDeletion";

/**
 * Self-service soft-delete for the signed-in mobile user. Reuses the same
 * pending_deletion pipeline as admin deletion after self-specific guards.
 */
export async function executeRequestSelfAccountDeletion(input: {
  db: Firestore;
  auth: AuthGateway;
  callerUid: string;
  data: unknown;
  nowMs?: number;
  graceDays?: number;
}): Promise<RequestUserDeletionResult> {
  const { db, auth, callerUid } = input;
  const { reason, confirmEmail } = validateSelfAccountDeletionInput(input.data);

  const target = await auth.getUser(callerUid);
  if (!target) {
    throw new DeletionGuardError("not-found", "Target user not found.");
  }
  assertSelfDeletable({ callerUid, target, confirmEmail });

  return executePendingUserDeletion({
    db,
    auth,
    callerUid,
    targetUserId: callerUid,
    reason,
    nowMs: input.nowMs,
    graceDays: input.graceDays,
  });
}

/**
 * Authenticated user deletes their own account (soft-delete + grace period).
 * Admin accounts must use the admin panel instead.
 */
export const requestSelfAccountDeletion = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    if (request.auth.token.admin === true) {
      throw new HttpsError(
        "permission-denied",
        "Admin accounts must be deleted from the admin panel.",
      );
    }
    try {
      return await executeRequestSelfAccountDeletion({
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
