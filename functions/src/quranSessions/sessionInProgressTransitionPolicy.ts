/** Q-SL-03: inProgress only when startsAt passed and join logged at/after start. */
export function shouldTransitionToInProgress(params: {
  startsAt: Date;
  now: Date;
  joinEventAtMs: number;
}): boolean {
  if (params.joinEventAtMs < params.startsAt.getTime()) {
    return false;
  }
  return params.now.getTime() >= params.startsAt.getTime();
}
