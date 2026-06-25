import { SessionLifecycleStatus } from './session-lifecycle-status.enum';

/**
 * How far back to look for sessions that may still be operationally active.
 *
 * 4 hours covers any live `in_progress` session that started more than 30
 * minutes ago — the previous 30-minute back-window excluded currently-live
 * sessions whose scheduled start was >30 min in the past. The window stays
 * bounded (6 h total) with `limit(26)`, so read cost is controlled.
 */
export const ACTIVE_SESSION_WINDOW_BEFORE_MS = 4 * 60 * 60 * 1000;

/** How far after scheduled start an booking remains in the active window. */
export const ACTIVE_SESSION_WINDOW_AFTER_MS = 2 * 60 * 60 * 1000;

/** Recently-ended visibility after call end or session end. */
export const ACTIVE_SESSION_RECENTLY_ENDED_MS = 30 * 60 * 1000;

export const ACTIVE_SESSION_PAGE_SIZE = 25;

export const ACTIVE_SESSION_DEFAULT_SORT = {
  field: 'startsAt',
  direction: 'asc',
} as const;

export const ACTIVE_SESSION_SORT_FIELDS = ['startsAt'] as const;

/**
 * Backend-supported operational states derived from booking lifecycle +
 * aggregated `callTracking/summary` (never raw events).
 */
export enum ActiveSessionOperationalStatus {
  ScheduledStartingSoon = 'scheduled_starting_soon',
  WaitingForTeacher = 'waiting_for_teacher',
  WaitingForStudent = 'waiting_for_student',
  Live = 'live',
  InterruptedReconnecting = 'interrupted_reconnecting',
  RecentlyEnded = 'recently_ended',
  NoShowCandidate = 'no_show_candidate',
}

/** UI filter tabs — subset map to [ActiveSessionOperationalStatus]. */
export enum ActiveSessionOperationalFilter {
  All = 'all',
  LiveNow = 'live_now',
  WaitingForTeacher = 'waiting_for_teacher',
  WaitingForStudent = 'waiting_for_student',
  LateNoShow = 'late_no_show',
  Interrupted = 'interrupted',
  RecentlyEnded = 'recently_ended',
}

/** Lifecycle values included in the server-side active window query. */
export const ACTIVE_SESSION_SERVER_LIFECYCLE_STATUSES: readonly SessionLifecycleStatus[] = [
  SessionLifecycleStatus.Scheduled,
  SessionLifecycleStatus.Confirmed,
  SessionLifecycleStatus.PendingPayment,
  SessionLifecycleStatus.InProgress,
  SessionLifecycleStatus.Rescheduled,
  SessionLifecycleStatus.Completed,
  SessionLifecycleStatus.Incomplete,
];

export interface ActiveSessionFilters {
  readonly operationalFilter: ActiveSessionOperationalFilter;
  /** Injectable clock for tests. Defaults to `new Date()` in repository. */
  readonly now?: Date;
}

export interface ActiveSessionWindow {
  readonly startsFrom: Date;
  readonly startsTo: Date;
}

export function resolveActiveSessionWindow(now: Date = new Date()): ActiveSessionWindow {
  return {
    startsFrom: new Date(now.getTime() - ACTIVE_SESSION_WINDOW_BEFORE_MS),
    startsTo: new Date(now.getTime() + ACTIVE_SESSION_WINDOW_AFTER_MS),
  };
}

export function matchesOperationalFilter(
  status: ActiveSessionOperationalStatus,
  filter: ActiveSessionOperationalFilter,
  flags: {
    readonly teacherLate: boolean;
    readonly studentLate: boolean;
  },
): boolean {
  switch (filter) {
    case ActiveSessionOperationalFilter.All:
      return true;
    case ActiveSessionOperationalFilter.LiveNow:
      return status === ActiveSessionOperationalStatus.Live;
    case ActiveSessionOperationalFilter.WaitingForTeacher:
      return status === ActiveSessionOperationalStatus.WaitingForTeacher;
    case ActiveSessionOperationalFilter.WaitingForStudent:
      return status === ActiveSessionOperationalStatus.WaitingForStudent;
    case ActiveSessionOperationalFilter.LateNoShow:
      return (
        status === ActiveSessionOperationalStatus.NoShowCandidate ||
        flags.teacherLate ||
        flags.studentLate
      );
    case ActiveSessionOperationalFilter.Interrupted:
      return status === ActiveSessionOperationalStatus.InterruptedReconnecting;
    case ActiveSessionOperationalFilter.RecentlyEnded:
      return status === ActiveSessionOperationalStatus.RecentlyEnded;
  }
}
