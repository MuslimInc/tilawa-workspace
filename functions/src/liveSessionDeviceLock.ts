/**
 * Server-side gate for the per-session live device lock (ADR-008 Phase 2).
 *
 * Evaluated at call time from the environment, mirroring the multi-device login
 * gate. Version-independent and unspoofable (clients cannot set it), with no
 * per-call Firestore read. Default **off**; set
 * `LIVE_SESSION_DEVICE_LOCK_ENABLED=true` in the staging Functions environment.
 *
 * When on, `issueSessionRtcToken` acquires a per-participant lease lock at
 * `quran_sessions/{sessionId}.liveLocks.{uid}` before minting the RTC token,
 * mints LiveKit tokens with `identity = uid#deviceId` for targeted eviction, and
 * sends a device-targeted `session_taken_over` FCM on takeover. When off, the
 * legacy path is unchanged (no lock, `identity = uid`).
 */
export function isLiveSessionDeviceLockEnabled(): boolean {
  return process.env.LIVE_SESSION_DEVICE_LOCK_ENABLED === "true";
}
