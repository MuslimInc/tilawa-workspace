import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";

/**
 * Shared Firestore handle for integration tests. These run under
 * `firebase emulators:exec --only firestore`, which sets
 * `FIRESTORE_EMULATOR_HOST` so the Admin SDK talks to the local emulator.
 *
 * A `demo-` project id keeps everything offline (no credentials required).
 *
 * Prerequisite: the Firestore emulator requires JDK 21+ (firebase-tools dropped
 * Java < 21). Run with `JAVA_HOME="$(/usr/libexec/java_home -v 21)"` if your
 * default `java` is older. Files run serialized (`--test-concurrency=1`) because
 * they share one emulator DB and clear it between tests.
 */
const PROJECT_ID = process.env.GCLOUD_PROJECT || "demo-tilawa";

export function db(): Firestore {
  if (getApps().length === 0) {
    initializeApp({ projectId: PROJECT_ID });
  }
  return getFirestore();
}

/** Default epoch for integration callers after single-active-device guards. */
export const DEFAULT_SESSION_EPOCH = 1;

/** Seeds `users/{uid}.session` so callable epoch guards accept requests. */
export async function seedUserSession(
  uid: string,
  epoch = DEFAULT_SESSION_EPOCH,
  activeDeviceId = "integration-device",
): Promise<void> {
  await db()
    .collection("users")
    .doc(uid)
    .set(
      {
        session: { epoch, activeDeviceId },
      },
      { merge: true },
    );
}

/** Adds `sessionEpoch` to callable request payloads. */
export function withSessionEpoch<T extends Record<string, unknown>>(
  data: T,
  epoch = DEFAULT_SESSION_EPOCH,
): T & { sessionEpoch: number } {
  return { ...data, sessionEpoch: epoch };
}

/** Wipes all documents between tests via the emulator's REST clear endpoint. */
export async function clearFirestore(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) {
    throw new Error(
      "FIRESTORE_EMULATOR_HOST not set — run via `npm run test:integration`.",
    );
  }
  const url = `http://${host}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear emulator (${res.status}).`);
  }
}

/** Seeds platform + market policy docs required for production booking enforcement. */
export async function seedDefaultBookingPolicy(
  countryCode = "EG",
): Promise<void> {
  await db()
    .collection("quran_session_platform_config")
    .doc("global")
    .set({
      quranSessionsEnabled: true,
      studentEntryEnabled: true,
      bookingEnabled: true,
      bookingMode: "requiresTutorApproval",
      sessionMode: "freeBeta",
      enabledCallProviders: ["external", "mock"],
      childAgeThreshold: 14,
      genderMatchingEnabled: true,
    });

  await db()
    .collection("quran_session_market_configs")
    .doc(countryCode)
    .set({
      isEnabled: true,
      minSessionPrice: 0,
      currencyCode: "EGP",
      cities: [
        {
          cityId: "cairo",
          isEnabled: true,
          minSessionPrice: 0,
        },
      ],
      genderMatchingEnabled: true,
      minBookingNoticeMinutes: 60,
      maxConcurrentUpcomingPerStudent: 3,
      joinWindowLeadMinutes: 15,
    });
}

/** Merges platform config without dropping required booking policy fields. */
export async function patchPlatformConfig(
  patch: Record<string, unknown>,
): Promise<void> {
  await db()
    .collection("quran_session_platform_config")
    .doc("global")
    .set(patch, { merge: true });
}

/** Opt into legacy auto-confirm booking for tests that expect immediate scheduling. */
export async function patchAutoConfirmBooking(): Promise<void> {
  await patchPlatformConfig({ bookingMode: "autoConfirm" });
}

/** Clears emulator and seeds default booking policy fixtures. */
export async function prepareIntegrationFirestore(
  countryCode = "EG",
): Promise<void> {
  await clearFirestore();
  await seedDefaultBookingPolicy(countryCode);
}
