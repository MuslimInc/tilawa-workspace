import { JOIN_WINDOW_LEAD_MS } from "./platformSchedulingPolicy";

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
