import { Timestamp } from "firebase-admin/firestore";

/**
 * Pure builders for the teacher dashboard read-model document at
 * `quran_teacher_profiles/{teacherProfileId}/dashboard/summary`.
 *
 * Design: the summary mirrors the *raw* Firestore shapes the app already
 * decodes (camelCase fields, Timestamps) and does NOT re-classify sessions
 * server-side. Lifecycle classification (pending vs upcoming vs booked
 * starts) stays in the Dart domain layer so the projection cannot drift from
 * `SessionListClassifier` / `resolveLifecycleStatusRawFromFirestore`.
 */

/// Max session entries embedded in the summary doc. Mirrors the dashboard's
/// bounded consumption; beyond this the client falls back to direct queries.
/// ~0.5 KB per entry keeps the doc far below the 1 MiB Firestore limit.
export const MAX_DASHBOARD_SESSION_ENTRIES = 200;

/// Dashboard availability horizon cap — mirrors
/// `GetTeacherDashboardUseCase._dashboardHorizonDays` on mobile.
export const DEFAULT_DASHBOARD_HORIZON_DAYS = 14;

/// Discriminator for collection-group queries over `dashboard/*` docs.
export const DASHBOARD_SUMMARY_DOC_TYPE = "teacher_dashboard_summary";

/// Firestore defaults mirroring `marketSchedulingConfigDtoFromMap` (Dart).
const SCHEDULING_CONFIG_DEFAULTS: Record<string, unknown> = {
  schedulingMode: "recurring",
  weekStartDay: "sat",
  weekScopedDashboardEnabled: true,
  fridayReviewReminderEnabled: true,
  reminderLocalHour: 10,
  bookingHorizonDays: 30,
  policyVersion: 1,
};

export interface SourceDoc {
  id: string;
  data: Record<string, unknown>;
}

export interface SessionsSection {
  sessions: Array<Record<string, unknown>>;
  sessionsTruncated: boolean;
}

/// Session entry fields copied into the summary. Matches the superset the
/// app's `_mapDoc` (firestore_session_repository.dart) reads, minus
/// `joinToken`: join credentials are issued per-user via callable and must
/// not be denormalized into a long-lived document.
const SESSION_ENTRY_FIELDS = [
  "bookingId",
  "teacherId",
  "studentId",
  "startsAt",
  "endsAt",
  "callType",
  "status",
  "lifecycleStatus",
  "cancelledByRole",
  "cancellationReason",
  "lastActionReason",
  "meetingLink",
  "meeting_link",
  "callRoomId",
  "bookingType",
  "callProvider",
  "providerSessionId",
  "participants",
  "notes",
  "allowedActionsTeacher",
] as const;

export function projectSessionEntry(doc: SourceDoc): Record<string, unknown> {
  const entry: Record<string, unknown> = { id: doc.id };
  for (const field of SESSION_ENTRY_FIELDS) {
    const value = doc.data[field];
    if (value !== undefined) {
      entry[field] = value;
    }
  }
  return entry;
}

/**
 * Builds the sessions section from a query result fetched with
 * `limit(MAX_DASHBOARD_SESSION_ENTRIES + 1)` — the extra row is the
 * truncation probe and is not embedded.
 */
export function buildSessionsSection(docs: SourceDoc[]): SessionsSection {
  const truncated = docs.length > MAX_DASHBOARD_SESSION_ENTRIES;
  const bounded = truncated
    ? docs.slice(0, MAX_DASHBOARD_SESSION_ENTRIES)
    : docs;
  return {
    sessions: bounded.map(projectSessionEntry),
    sessionsTruncated: truncated,
  };
}

/// Override entry fields — matches the app's override decode
/// (firestore_schedule_repository.dart `getOverrides`).
export function projectOverrideEntry(doc: SourceDoc): Record<string, unknown> {
  return {
    date: typeof doc.data.date === "string" ? doc.data.date : doc.id,
    type: typeof doc.data.type === "string" ? doc.data.type : "unavailable",
    intervals: Array.isArray(doc.data.intervals) ? doc.data.intervals : [],
    ...(typeof doc.data.reason === "string" ? { reason: doc.data.reason } : {}),
  };
}

export function buildOverridesSection(
  docs: SourceDoc[],
): Array<Record<string, unknown>> {
  return docs.map(projectOverrideEntry);
}

/// The weekly schedule doc is small; embed it verbatim (null when absent).
export function buildWeeklyScheduleSection(
  scheduleData: Record<string, unknown> | null,
): Record<string, unknown> | null {
  return scheduleData;
}

export interface TeacherSection {
  userId: string;
  displayName: string | null;
  countryCode: string | null;
}

export function buildTeacherSection(
  teacherProfileData: Record<string, unknown>,
  countryCode: string | null,
): TeacherSection {
  return {
    userId:
      typeof teacherProfileData.userId === "string"
        ? teacherProfileData.userId
        : "",
    displayName:
      typeof teacherProfileData.displayName === "string"
        ? teacherProfileData.displayName
        : null,
    countryCode,
  };
}

export interface ResolvedSchedulingConfig {
  config: Record<string, unknown>;
  source: "market" | "global" | "defaults";
}

/**
 * Resolution mirrors `GetTeacherDashboardUseCase._resolveSchedulingConfig`:
 * market override doc wins when it has a non-empty `scheduling` map, else
 * global platform config, else Dart-side defaults.
 */
export function resolveSchedulingConfigSection(
  marketScheduling: Record<string, unknown> | null,
  globalScheduling: Record<string, unknown> | null,
): ResolvedSchedulingConfig {
  if (marketScheduling != null && Object.keys(marketScheduling).length > 0) {
    return {
      config: { ...SCHEDULING_CONFIG_DEFAULTS, ...marketScheduling },
      source: "market",
    };
  }
  if (globalScheduling != null && Object.keys(globalScheduling).length > 0) {
    return {
      config: { ...SCHEDULING_CONFIG_DEFAULTS, ...globalScheduling },
      source: "global",
    };
  }
  return { config: { ...SCHEDULING_CONFIG_DEFAULTS }, source: "defaults" };
}

/// min(bookingHorizonDays, 14) — mirrors the mobile dashboard cap.
export function resolveHorizonDays(
  schedulingConfig: Record<string, unknown>,
): number {
  const raw = schedulingConfig.bookingHorizonDays;
  const days =
    typeof raw === "number" && Number.isFinite(raw) && raw > 0
      ? Math.floor(raw)
      : (SCHEDULING_CONFIG_DEFAULTS.bookingHorizonDays as number);
  return Math.min(days, DEFAULT_DASHBOARD_HORIZON_DAYS);
}

/// `yyyy-MM-dd` key matching the app's override date keys.
export function overrideDateKey(date: Date): string {
  const y = date.getUTCFullYear().toString().padStart(4, "0");
  const m = (date.getUTCMonth() + 1).toString().padStart(2, "0");
  const d = date.getUTCDate().toString().padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export interface OverrideWindow {
  fromKey: string;
  toKeyExclusive: string;
}

/**
 * Override window in date keys. Padded one day on each side so teacher-local
 * calendar days that straddle UTC midnight are always covered; the client
 * filters precisely by its own timezone-aware slot generation.
 */
export function overrideWindow(now: Date, horizonDays: number): OverrideWindow {
  const dayMs = 24 * 60 * 60 * 1000;
  return {
    fromKey: overrideDateKey(new Date(now.getTime() - dayMs)),
    toKeyExclusive: overrideDateKey(
      new Date(now.getTime() + (horizonDays + 2) * dayMs),
    ),
  };
}

/// Timestamp lower bound for the sessions query (`endsAt >= now`), matching
/// the app's `getTeacherUpcomingSessions` filter.
export function sessionsWindowStart(now: Date): Timestamp {
  return Timestamp.fromDate(now);
}
