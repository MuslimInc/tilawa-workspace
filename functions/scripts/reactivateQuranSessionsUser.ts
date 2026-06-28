/**
 * Reactivates a Quran Sessions user (clears suspension) via Admin SDK.
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   npm run admin:reactivate-quran-sessions-user -- --userId=STUDENT_AUTH_UID
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const profileField = "quranSessionsProfile";

function parseUserId(): string {
  const arg = process.argv.find((value) => value.startsWith("--userId="));
  const userId = arg?.split("=")[1]?.trim();
  if (!userId) {
    throw new Error("--userId is required (Firebase Auth UID of the student).");
  }
  return userId;
}

async function main(): Promise<void> {
  const projectId = process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app";
  initializeApp({ projectId });
  const userId = parseUserId();
  const db = getFirestore();
  const userRef = db.collection("users").doc(userId);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw new Error(`User not found: ${userId}`);
  }

  const userData = userSnap.data() ?? {};
  const profile =
    (userData[profileField] as Record<string, unknown> | undefined) ?? {};

  if (!userData[profileField]) {
    throw new Error(`User ${userId} has no quranSessionsProfile.`);
  }

  const beforeStatus = (profile.accountStatus as string | undefined) ?? "active";
  const beforeReason = profile.restrictionReason as string | undefined;

  await userRef.update({
    [`${profileField}.accountStatus`]: "active",
    [`${profileField}.restrictionReason`]: FieldValue.delete(),
    [`${profileField}.updatedAt`]: FieldValue.serverTimestamp(),
  });

  const afterSnap = await userRef.get();
  const afterProfile =
    (afterSnap.data()?.[profileField] as Record<string, unknown> | undefined) ??
    {};

  console.log(`Reactivated Quran Sessions user ${userId}`);
  console.log(`  before: accountStatus=${beforeStatus}, restrictionReason=${beforeReason ?? "(none)"}`);
  console.log(
    `  after:  accountStatus=${afterProfile.accountStatus ?? "(missing)"}, restrictionReason=${afterProfile.restrictionReason ?? "(deleted)"}`,
  );
}

void main();
