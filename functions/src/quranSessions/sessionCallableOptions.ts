/**
 * Stable-scope Quran Sessions HTTPS callable options.
 *
 * App Check enforcement is opt-in via `QURAN_SESSIONS_ENFORCE_APP_CHECK=true`
 * at deploy/runtime. Default remains `false` so staging/dev clients without
 * attestation keep working until ops flips the flag and redeploys.
 */
export function isSessionAppCheckEnforced(): boolean {
  return process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK === "true";
}

/** Shared `onCall` options for stable-scope session callables. */
export const sessionCallableHttpsOptions = {
  enforceAppCheck: isSessionAppCheckEnforced(),
};
