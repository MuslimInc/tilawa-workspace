/**
 * Stable-scope Quran Sessions HTTPS callable options.
 *
 * App Check enforcement is opt-in via `QURAN_SESSIONS_ENFORCE_APP_CHECK=true`
 * at deploy/runtime. Default remains `false` so staging/dev clients without
 * attestation keep working until ops flips the flag and redeploys.
 *
 * The exported option objects capture the env value at module load, so a
 * change requires a functions redeploy — enforcement is deployment-controlled,
 * never a runtime or admin-panel setting. Production enforcement additionally
 * requires the completed staging evidence and rollback rehearsal recorded in
 * docs/quran-sessions/production-readiness-checklist.md § 3a.
 */
export function isSessionAppCheckEnforced(): boolean {
  return process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK === "true";
}

/**
 * Warm-instance floor for the *pricing-quote* callables only. Cold starts add
 * multiple seconds to the first booking-screen quote (proven by the
 * `coldStart`/`sinceModuleLoadMs` timing logs in `getBookingPricingQuote`:
 * 2202ms cold → 362ms warm on the same session). Set
 * `QURAN_SESSIONS_MIN_INSTANCES=1` (or higher) in the deploy env to keep an
 * instance warm and remove that spin-up penalty. Default `0` preserves the
 * current cost profile until ops opts in.
 *
 * Scoped deliberately to the read/preview path (`getBookingPricingQuote` +
 * `getBookingPricingQuotes`) — the two callables on the discovery→booking flow
 * whose latency the student sees before acting. The mutation callables
 * (create/cancel/complete/reschedule/RTC) are user-initiated after the screen
 * is interactive, so warming all ~11 session callables would add cost without a
 * comparable UX win.
 */
export function sessionMinInstances(): number {
  const raw = Number.parseInt(
    process.env.QURAN_SESSIONS_MIN_INSTANCES ?? "",
    10,
  );
  return Number.isFinite(raw) && raw > 0 ? raw : 0;
}

/** Shared `onCall` options for stable-scope session callables. */
export const sessionCallableHttpsOptions = {
  enforceAppCheck: isSessionAppCheckEnforced(),
};

/**
 * Options for the latency-sensitive pricing-quote callables: shared options
 * plus an opt-in warm-instance floor ([sessionMinInstances]).
 */
export const sessionPricingQuoteHttpsOptions = {
  ...sessionCallableHttpsOptions,
  minInstances: sessionMinInstances(),
};
