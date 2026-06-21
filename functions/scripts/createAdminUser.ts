/**
 * Create or update Firebase Auth admin user + `{ admin: true }` claim.
 *
 * Usage:
 *   ADMIN_EMAIL=... ADMIN_PASSWORD=... npm run admin:create-user
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or gcloud application-default creds.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

initializeApp({
  projectId: process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app",
});

async function main(): Promise<void> {
  const email = process.env.ADMIN_EMAIL?.trim();
  const password = process.env.ADMIN_PASSWORD;

  if (!email || !password) {
    throw new Error("ADMIN_EMAIL and ADMIN_PASSWORD env vars required.");
  }

  const auth = getAuth();
  let user;

  try {
    user = await auth.getUserByEmail(email);
    await auth.updateUser(user.uid, { password });
    console.log(`Updated password for existing user ${email}`);
  } catch (error: unknown) {
    const code =
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      (error as { code: string }).code;

    if (code !== "auth/user-not-found") {
      throw error;
    }

    user = await auth.createUser({ email, password });
    console.log(`Created user ${email}`);
  }

  await auth.setCustomUserClaims(user.uid, { admin: true });
  console.log(`Set admin claim on uid=${user.uid}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
