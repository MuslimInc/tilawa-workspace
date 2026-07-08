/**
 * Seeds `quran_session_platform_config/global` for staging/production rollout.
 *
 * A `--mode` argument is REQUIRED so the script can never silently re-seed a
 * configuration meant for a different phase:
 *
 *   closed-testing  external + mock providers, sessionMode=freeBeta.
 *                   Required before inviting Learn Quran closed testers —
 *                   Play builds exclude native Agora/LiveKit SDKs, so the
 *                   config must not expose RTC providers clients cannot join.
 *   video-qa        mock + agora providers, sessionMode=videoOnly.
 *                   MeMuslim staging video QA (staging.video.local.json).
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   npm run seed:platform-config -- --mode closed-testing            # dry run
 *   npm run seed:platform-config:apply -- --mode closed-testing      # write
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { FIREBASE_PROJECT_ID } from "../src/github";

const APPLY = process.argv.includes("--apply");
const DOC_PATH = "quran_session_platform_config/global";

const SHARED_PLATFORM_CONFIG: Record<string, unknown> = {
  quranTutorBookingMode: "requiresTutorApproval",
  childAgeThreshold: 14,
  genderMatchingEnabled: true,
  globalAllowMaleTeacherFemaleStudent: true,
  globalAllowFemaleTeacherMaleStudent: true,
  // Config-driven market gate. Production: Egypt only. Open new markets by
  // adding codes here (or flip enableForAllMarkets) — no code change needed.
  enableForAllMarkets: false,
  enabledMarketCodes: ["EG"],
};

const MODE_PRESETS: Record<string, Record<string, unknown>> = {
  "closed-testing": {
    ...SHARED_PLATFORM_CONFIG,
    sessionMode: "freeBeta",
    enabledCallProviders: ["external", "mock"],
  },
  "video-qa": {
    ...SHARED_PLATFORM_CONFIG,
    sessionMode: "videoOnly",
    enabledCallProviders: ["mock", "agora"],
  },
};

function resolveMode(): string {
  const index = process.argv.indexOf("--mode");
  const mode = index >= 0 ? process.argv[index + 1] : undefined;
  if (mode !== undefined && MODE_PRESETS[mode] !== undefined) {
    return mode;
  }
  const known = Object.keys(MODE_PRESETS).join(" | ");
  console.error(
    mode === undefined
      ? `Missing required --mode argument (${known}).`
      : `Unknown --mode "${mode}" (expected: ${known}).`,
  );
  console.error("Presets:");
  for (const [name, preset] of Object.entries(MODE_PRESETS)) {
    console.error(`  ${name}: ${JSON.stringify(preset)}`);
  }
  process.exit(1);
}

async function main(): Promise<void> {
  const mode = resolveMode();
  const config: Record<string, unknown> = {
    ...MODE_PRESETS[mode],
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (!APPLY) {
    console.log(`Dry run (mode=${mode}). Would write ${DOC_PATH}:`);
    console.log(JSON.stringify(config, null, 2));
    console.log("Re-run with --apply to write.");
    return;
  }

  initializeApp({ projectId: FIREBASE_PROJECT_ID });
  const db = getFirestore();
  await db.doc(DOC_PATH).set(config, { merge: true });
  console.log(
    `Wrote ${DOC_PATH} (mode=${mode}) in project ${FIREBASE_PROJECT_ID}.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
