/**
 * Server-side gate for multi-device login (ADR-008 Phase 1).
 *
 * Evaluated at call time from the environment, mirroring the payment provider
 * env gate. Version-independent and unspoofable (clients cannot set it), with
 * no per-call Firestore read. Default **on**; set
 * `MULTI_DEVICE_LOGIN_ENABLED=false` to force legacy single-device behavior.
 *
 * When on, `registerActiveDevice` stops the automatic single-device
 * enforcement (no `revokeRefreshTokens`, no `session_revoked` push, no
 * exclusive `activeDeviceId`) and session callables tolerate-and-ignore
 * `sessionEpoch`. When off, all legacy single-device behavior is unchanged.
 */
export function isMultiDeviceLoginEnabled(): boolean {
  return process.env.MULTI_DEVICE_LOGIN_ENABLED !== "false";
}
