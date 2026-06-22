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
