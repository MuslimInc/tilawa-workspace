import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { requireAdmin } from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

export type TeacherApplicationDiscoverability =
  | "none"
  | "profileOnly"
  | "profileAndEmptyState";

const DISCOVERABILITY_VALUES: readonly TeacherApplicationDiscoverability[] = [
  "none",
  "profileOnly",
  "profileAndEmptyState",
];

export interface UpdatePlatformConfigRequest {
  quranSessionsEnabled: boolean;
  studentEntryEnabled: boolean;
  bookingEnabled: boolean;
  sessionMode: "videoOnly";
  bookingMode: "requiresTutorApproval" | "autoConfirm";
  defaultBookingMode?: "requiresTutorApproval" | "autoConfirm";
  quranTutorBookingMode?: "requiresTutorApproval" | "autoConfirm";
  defaultJoinWindowLeadMs: number;
  defaultTutorApprovalSlaMs: number;
  defaultMinBookingNoticeMs: number;
  defaultMaxUpcomingPerStudent: number;
  childAgeThreshold?: number;
  // Tutor (teacher application) entry — admin-controlled. Optional so legacy
  // callers keep working; when omitted, `{ merge: true }` preserves the
  // existing Firestore values instead of clobbering them.
  teacherApplicationEnabled?: boolean;
  teacherApplicationEntryEnabled?: boolean;
  homeTeacherApplicationCardEnabled?: boolean;
  teacherApplicationDiscoverability?: TeacherApplicationDiscoverability;
}

/** Collects only the tutor-entry fields that were explicitly provided. */
function pickTeacherApplicationFields(
  data: Partial<UpdatePlatformConfigRequest>,
): Record<string, boolean | string> {
  const fields: Record<string, boolean | string> = {};
  if (data.teacherApplicationEnabled != null) {
    fields.teacherApplicationEnabled = data.teacherApplicationEnabled;
  }
  if (data.teacherApplicationEntryEnabled != null) {
    fields.teacherApplicationEntryEnabled = data.teacherApplicationEntryEnabled;
  }
  if (data.homeTeacherApplicationCardEnabled != null) {
    fields.homeTeacherApplicationCardEnabled =
      data.homeTeacherApplicationCardEnabled;
  }
  if (data.teacherApplicationDiscoverability != null) {
    fields.teacherApplicationDiscoverability =
      data.teacherApplicationDiscoverability;
  }
  return fields;
}

function resolveBookingMode(
  data: Partial<UpdatePlatformConfigRequest>,
): "requiresTutorApproval" | "autoConfirm" | undefined {
  return data.bookingMode ?? data.defaultBookingMode ?? data.quranTutorBookingMode;
}

export function validateUpdatePlatformConfig(data: Partial<UpdatePlatformConfigRequest>): void {
  if (typeof data.quranSessionsEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "quranSessionsEnabled (boolean) required.");
  }
  if (typeof data.studentEntryEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "studentEntryEnabled (boolean) required.");
  }
  if (typeof data.bookingEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "bookingEnabled (boolean) required.");
  }
  if (data.sessionMode !== "videoOnly") {
    throw new HttpsError("invalid-argument", "sessionMode must be 'videoOnly'.");
  }
  const bookingMode = resolveBookingMode(data);
  if (bookingMode !== "requiresTutorApproval" && bookingMode !== "autoConfirm") {
    throw new HttpsError("invalid-argument", "bookingMode must be 'requiresTutorApproval' or 'autoConfirm'.");
  }
  if (typeof data.defaultJoinWindowLeadMs !== "number" || !Number.isFinite(data.defaultJoinWindowLeadMs) || data.defaultJoinWindowLeadMs < 0) {
    throw new HttpsError("invalid-argument", "defaultJoinWindowLeadMs must be a finite number >= 0.");
  }
  if (typeof data.defaultTutorApprovalSlaMs !== "number" || !Number.isFinite(data.defaultTutorApprovalSlaMs) || data.defaultTutorApprovalSlaMs < 0) {
    throw new HttpsError("invalid-argument", "defaultTutorApprovalSlaMs must be a finite number >= 0.");
  }
  if (typeof data.defaultMinBookingNoticeMs !== "number" || !Number.isFinite(data.defaultMinBookingNoticeMs) || data.defaultMinBookingNoticeMs < 0) {
    throw new HttpsError("invalid-argument", "defaultMinBookingNoticeMs must be a finite number >= 0.");
  }
  if (typeof data.defaultMaxUpcomingPerStudent !== "number" || !Number.isFinite(data.defaultMaxUpcomingPerStudent) || data.defaultMaxUpcomingPerStudent < 0) {
    throw new HttpsError("invalid-argument", "defaultMaxUpcomingPerStudent must be a finite number >= 0.");
  }
  if (
    data.childAgeThreshold != null &&
    (typeof data.childAgeThreshold !== "number" ||
      !Number.isFinite(data.childAgeThreshold) ||
      data.childAgeThreshold <= 0)
  ) {
    throw new HttpsError("invalid-argument", "childAgeThreshold must be a finite number > 0.");
  }
  validateOptionalBoolean(data.teacherApplicationEnabled, "teacherApplicationEnabled");
  validateOptionalBoolean(data.teacherApplicationEntryEnabled, "teacherApplicationEntryEnabled");
  validateOptionalBoolean(data.homeTeacherApplicationCardEnabled, "homeTeacherApplicationCardEnabled");
  if (
    data.teacherApplicationDiscoverability != null &&
    !DISCOVERABILITY_VALUES.includes(data.teacherApplicationDiscoverability)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "teacherApplicationDiscoverability must be one of none|profileOnly|profileAndEmptyState.",
    );
  }
}

function validateOptionalBoolean(value: unknown, field: string): void {
  if (value != null && typeof value !== "boolean") {
    throw new HttpsError("invalid-argument", `${field} must be a boolean when provided.`);
  }
}

export const updatePlatformConfig = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const adminUid = requireAdmin(request);
    const data = request.data as Partial<UpdatePlatformConfigRequest>;

    validateUpdatePlatformConfig(data);
    const bookingMode = resolveBookingMode(data)!;
    const teacherApplicationFields = pickTeacherApplicationFields(data);

    const db = getFirestore();
    const batch = db.batch();

    const configRef = db.collection("quran_session_platform_config").doc("global");
    batch.set(configRef, {
      quranSessionsEnabled: data.quranSessionsEnabled,
      studentEntryEnabled: data.studentEntryEnabled,
      bookingEnabled: data.bookingEnabled,
      sessionMode: data.sessionMode,
      bookingMode,
      childAgeThreshold: data.childAgeThreshold ?? 14,
      defaultJoinWindowLeadMs: data.defaultJoinWindowLeadMs,
      defaultTutorApprovalSlaMs: data.defaultTutorApprovalSlaMs,
      defaultMinBookingNoticeMs: data.defaultMinBookingNoticeMs,
      defaultMaxUpcomingPerStudent: data.defaultMaxUpcomingPerStudent,
      ...teacherApplicationFields,
      updatedBy: adminUid,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    batch.set(db.collection("quran_session_events").doc(), {
      timestamp: FieldValue.serverTimestamp(),
      aggregateId: "global",
      actorId: adminUid,
      actorRole: "admin",
      action: "update_platform_config",
      source: "adminPanel",
      quranSessionsEnabled: data.quranSessionsEnabled,
      studentEntryEnabled: data.studentEntryEnabled,
      bookingEnabled: data.bookingEnabled,
      sessionMode: data.sessionMode,
      bookingMode,
      childAgeThreshold: data.childAgeThreshold ?? 14,
      defaultJoinWindowLeadMs: data.defaultJoinWindowLeadMs,
      defaultTutorApprovalSlaMs: data.defaultTutorApprovalSlaMs,
      defaultMinBookingNoticeMs: data.defaultMinBookingNoticeMs,
      defaultMaxUpcomingPerStudent: data.defaultMaxUpcomingPerStudent,
      ...teacherApplicationFields,
    });

    await batch.commit();

    return { success: true };
  }
);
