import { JOIN_WINDOW_LEAD_MS } from "./platformSchedulingPolicy";
import { isQaJoinWindowBypassEligible } from "./stagingQaJoinWindowBypass";

/** Q-VC-03: join allowed from 15m before startsAt until endsAt. */
export function isWithinJoinWindow(params: {
  startsAt: Date;
  endsAt: Date;
  now: Date;
  leadTimeMs?: number;
}): boolean {
  const lead = params.leadTimeMs ?? JOIN_WINDOW_LEAD_MS;
  const windowStart = params.startsAt.getTime() - lead;
  const nowMs = params.now.getTime();
  return nowMs >= windowStart && nowMs <= params.endsAt.getTime();
}

/** Join window check with staging-only QA uid bypass (window timing only). */
export function isWithinJoinWindowOrQaBypass(params: {
  startsAt: Date;
  endsAt: Date;
  now: Date;
  leadTimeMs?: number;
  uid?: string;
}): boolean {
  if (isQaJoinWindowBypassEligible(params.uid)) {
    return true;
  }
  return isWithinJoinWindow({
    startsAt: params.startsAt,
    endsAt: params.endsAt,
    now: params.now,
    leadTimeMs: params.leadTimeMs,
  });
}
