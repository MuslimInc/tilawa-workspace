/**
 * Verify existing Google-auth staging accounts before Maestro seed.
 *
 * Read-only against Firebase Auth + Firestore. Never writes passwords.
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   npm run verify:quran-staging-existing-auth-accounts
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth, type UserRecord } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

import {
  assertMaestroStagingProject,
  buildVerifyAccountResult,
  formatAuthAccountReport,
  MAESTRO_ACCOUNT_SPECS,
  resolveMaestroProjectId,
  type UserEmailRecord,
  findFirestoreUsersByEmail,
} from "../src/quranSessions/maestroStagingAccounts";

async function loadFirestoreUsers(): Promise<UserEmailRecord[]> {
  const db = getFirestore();
  const snapshot = await db.collection("users").get();
  return snapshot.docs.map((doc) => ({
    id: doc.id,
    email: doc.data().email as string | undefined,
  }));
}

async function lookupAuthUser(email: string): Promise<UserRecord | null> {
  const auth = getAuth();
  try {
    return await auth.getUserByEmail(email);
  } catch (error: unknown) {
    const code =
      typeof error === "object"
      && error !== null
      && "code" in error
      && (error as { code: string }).code;

    if (code === "auth/user-not-found") {
      return null;
    }
    throw error;
  }
}

async function main(): Promise<void> {
  const projectId = resolveMaestroProjectId();
  assertMaestroStagingProject(projectId);

  initializeApp({ projectId });
  const firestoreUsers = await loadFirestoreUsers();

  console.log(`verifyQuranStagingExistingAuthAccounts — project ${projectId}\n`);

  const results = [];
  for (const spec of MAESTRO_ACCOUNT_SPECS) {
    const authUser = await lookupAuthUser(spec.email);
    const firestoreUserIds = findFirestoreUsersByEmail(firestoreUsers, spec.email);
    const result = buildVerifyAccountResult({
      spec,
      authUser,
      firestoreUserIds,
    });
    results.push(result);
    console.log(`${formatAuthAccountReport(result)}\n`);
  }

  const failed = results.filter((result) => !result.pass);
  console.log("=== Summary ===");
  console.log(`${results.length - failed.length}/${results.length} accounts pass verification`);

  if (failed.length > 0) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
