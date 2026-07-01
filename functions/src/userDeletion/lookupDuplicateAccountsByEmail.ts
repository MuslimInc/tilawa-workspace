import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  adminAuthAccountLookup,
  AuthAccountLookup,
  AuthAccountSummary,
  lookupAuthAccountsByEmail,
} from "./authAccountLookup";
import { buildKeepGoogleDeletionPlan, normalizeLookupEmail } from "./duplicateAccountLogic";
import { mapGuardError } from "./requestUserDeletion";
import { DeletionGuardError } from "./userDeletionLogic";

export interface LookupDuplicateAccountsResult {
  email: string;
  accounts: AuthAccountSummary[];
  authScanTruncated: boolean;
  suggestedKeepGooglePlan: {
    keepUserId: string;
    deleteUserIds: string[];
  } | null;
}

export async function executeLookupDuplicateAccountsByEmail(input: {
  email: string;
  lookup?: AuthAccountLookup;
}): Promise<LookupDuplicateAccountsResult> {
  const email = normalizeLookupEmail(input.email);
  const result = await lookupAuthAccountsByEmail({
    db: getFirestore(),
    lookup: input.lookup ?? adminAuthAccountLookup(),
    email,
  });
  const suggested = buildKeepGoogleDeletionPlan(result.accounts);
  return {
    email: result.email,
    accounts: result.accounts,
    authScanTruncated: result.authScanTruncated,
    suggestedKeepGooglePlan: suggested
      ? {
          keepUserId: suggested.keepUserId,
          deleteUserIds: [...suggested.deleteUserIds],
        }
      : null,
  };
}

/**
 * Admin-only: lists every Auth account sharing an email, enriched with
 * Firestore/deletion state. Requires custom claim `{ admin: true }`.
 */
export const lookupDuplicateAccountsByEmail = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    try {
      const data = (request.data ?? {}) as { email?: string };
      return await executeLookupDuplicateAccountsByEmail({
        email: data.email ?? "",
      });
    } catch (error) {
      if (error instanceof DeletionGuardError) {
        mapGuardError(error);
      }
      throw error;
    }
  },
);
