/**
 * Seeds `quran_session_platform_config/global` for staging/production rollout.
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   npx ts-node --project tsconfig.scripts.json scripts/seedPlatformConfig.ts
 *   npx ts-node --project tsconfig.scripts.json scripts/seedPlatformConfig.ts --apply
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { FIREBASE_PROJECT_ID } from "../src/github";

const APPLY = process.argv.includes("--apply");
const DOC_PATH = "quran_session_platform_config/global";

const DEFAULT_PLATFORM_CONFIG: Record<string, unknown> = {
  quranTutorBookingMode: "requiresTutorApproval",
  sessionMode: "videoOnly",
  enabledCallProviders: ["mock", "agora"],
  childAgeThreshold: 14,
  genderMatchingEnabled: true,
  requireGuardianApprovalForChildren: true,
  globalAllowMaleTeacherFemaleStudent: true,
  globalAllowFemaleTeacherMaleStudent: true,
  updatedAt: FieldValue.serverTimestamp(),
};

async function main(): Promise<void> {
  if (!APPLY) {
    console.log(`Dry run. Would write ${DOC_PATH}:`);
    console.log(JSON.stringify(DEFAULT_PLATFORM_CONFIG, null, 2));
    console.log("Re-run with --apply to write.");
    return;
  }

  initializeApp({ projectId: FIREBASE_PROJECT_ID });
  const db = getFirestore();
  await db.doc(DOC_PATH).set(DEFAULT_PLATFORM_CONFIG, { merge: true });
  console.log(`Wrote ${DOC_PATH} in project ${FIREBASE_PROJECT_ID}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
