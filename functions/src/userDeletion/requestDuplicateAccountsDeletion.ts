import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { adminAuthGateway, AuthGateway } from "./authGateway";
import {
  adminAuthAccountLookup,
  AuthAccountLookup,
  lookupAuthAccountsByEmail,
} from "./authAccountLookup";
import {
  validateDuplicateDeletionPlan,
  validateDuplicateDeletionRequestInput,
} from "./duplicateAccountLogic";
import { DeletionGuardError } from "./userDeletionLogic";
import { executePurgeFirestoreOrphanUser } from "./purgeFirestoreOrphanUser";
import {
  executeRequestUserDeletion,
  mapGuardError,
  RequestUserDeletionResult,
} from "./requestUserDeletion";

export interface DuplicateAccountDeletionItemResult {
  targetUserId: string;
  status: "pending_deletion" | "already_pending" | "failed" | "purged";
  purgeAfter?: string;
  auditId?: string;
  message?: string;
}

export interface RequestDuplicateAccountsDeletionResult {
  email: string;
  keepUserId: string;
  results: DuplicateAccountDeletionItemResult[];
}

function isAlreadyPending(error: unknown): boolean {
  return (
    error instanceof DeletionGuardError &&
    error.code === "failed-precondition" &&
    error.message.includes("already pending")
  );
}

/**
 * Soft-deletes each selected duplicate via the existing requestUserDeletion
 * pipeline. Idempotent when a target is already pending_deletion.
 */
export async function executeRequestDuplicateAccountsDeletion(input: {
  auth: AuthGateway;
  callerUid: string;
  data: unknown;
  lookup?: AuthAccountLookup;
}): Promise<RequestDuplicateAccountsDeletionResult> {
  const parsed = validateDuplicateDeletionRequestInput(input.data);
  const lookup = await lookupAuthAccountsByEmail({
    db: getFirestore(),
    lookup: input.lookup ?? adminAuthAccountLookup(),
    email: parsed.email,
  });

  const plan = validateDuplicateDeletionPlan({
    callerUid: input.callerUid,
    accounts: lookup.accounts,
    keepUserId: parsed.keepUserId,
    deleteUserIds: parsed.deleteUserIds,
    forceDeleteGoogleAccount: parsed.forceDeleteGoogleAccount,
  });

  const db = getFirestore();
  const results: DuplicateAccountDeletionItemResult[] = [];
  const accountByUid = new Map(
    lookup.accounts.map((account) => [account.uid, account]),
  );

  for (const targetUserId of plan.deleteUserIds) {
    const account = accountByUid.get(targetUserId);
    try {
      if (account?.isFirestoreOnly === true) {
        const orphanResult = await executePurgeFirestoreOrphanUser({
          db,
          auth: input.auth,
          callerUid: input.callerUid,
          targetUserId,
          reason: `${parsed.reason} (duplicate email cleanup; kept ${plan.keepUserId})`,
        });
        results.push({
          targetUserId,
          status: "purged",
          auditId: orphanResult.auditId,
        });
        continue;
      }

      const result: RequestUserDeletionResult =
        await executeRequestUserDeletion({
          db,
          auth: input.auth,
          callerUid: input.callerUid,
          data: {
            targetUserId,
            reason: `${parsed.reason} (duplicate email cleanup; kept ${plan.keepUserId})`,
            confirmEmail: parsed.confirmEmail,
          },
        });
      results.push({
        targetUserId,
        status: "pending_deletion",
        purgeAfter: result.purgeAfter,
        auditId: result.auditId,
      });
    } catch (error) {
      if (isAlreadyPending(error)) {
        results.push({
          targetUserId,
          status: "already_pending",
          message:
            error instanceof Error ? error.message : "Already pending deletion.",
        });
        continue;
      }
      results.push({
        targetUserId,
        status: "failed",
        message: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const failed = results.filter((item) => item.status === "failed");
  if (failed.length > 0) {
    throw new DeletionGuardError(
      "failed-precondition",
      `Duplicate cleanup partially failed for: ${failed.map((f) => f.targetUserId).join(", ")}`,
    );
  }

  console.info("requestDuplicateAccountsDeletion", {
    adminUid: input.callerUid,
    email: parsed.email,
    keepUserId: plan.keepUserId,
    deletedCount: results.length,
  });

  return {
    email: parsed.email,
    keepUserId: plan.keepUserId,
    results,
  };
}

/**
 * Admin-only: marks selected duplicate accounts pending_deletion using the
 * existing soft-delete pipeline. Requires custom claim `{ admin: true }`.
 */
export const requestDuplicateAccountsDeletion = onCall(
  { enforceAppCheck: false, timeoutSeconds: 540 },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    try {
      return await executeRequestDuplicateAccountsDeletion({
        auth: adminAuthGateway(),
        callerUid: request.auth.uid,
        data: request.data,
      });
    } catch (error) {
      mapGuardError(error);
    }
  },
);

