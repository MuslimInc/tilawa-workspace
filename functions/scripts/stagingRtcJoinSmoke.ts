/**
 * Staging RTC join credential smoke — verifies Agora env is present before
 * enabling voice/video in platform config.
 *
 * Usage:
 *   FIREBASE_PROJECT_ID=quran-playera-app npx ts-node --project tsconfig.scripts.json scripts/stagingRtcJoinSmoke.ts
 */
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app";

function record(name: string, pass: boolean, detail: string): void {
  const icon = pass ? "PASS" : "FAIL";
  console.log(`[${icon}] ${name}: ${detail}`);
}

function main(): void {
  console.log(`RTC join smoke — project ${PROJECT_ID}\n`);

  const agoraAppId = process.env.AGORA_APP_ID?.trim() ?? "";
  const agoraCert = process.env.AGORA_APP_CERTIFICATE?.trim() ?? "";

  record(
    "agora_app_id_present",
    agoraAppId.length > 0,
    agoraAppId.length > 0 ? "AGORA_APP_ID set" : "AGORA_APP_ID missing",
  );
  record(
    "agora_certificate_present",
    agoraCert.length > 0,
    agoraCert.length > 0
      ? "AGORA_APP_CERTIFICATE set"
      : "AGORA_APP_CERTIFICATE missing",
  );

  const pass = agoraAppId.length > 0 && agoraCert.length > 0;
  console.log(`\nRTC join smoke ${pass ? "PASSED" : "FAILED"}`);
  if (!pass) {
    process.exitCode = 1;
  }
}

main();
