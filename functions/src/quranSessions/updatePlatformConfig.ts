import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { requireAdmin } from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

export interface UpdatePlatformConfigRequest {
  quranSessionsEnabled: boolean;
  studentEntryEnabled: boolean;
  bookingEnabled: boolean;
  sessionMode: "videoOnly";
  defaultBookingMode: "requiresTutorApproval" | "autoConfirm";
  defaultJoinWindowLeadMs: number;
  defaultTutorApprovalSlaMs: number;
  defaultMinBookingNoticeMs: number;
  defaultMaxUpcomingPerStudent: number;
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
  if (data.defaultBookingMode !== "requiresTutorApproval" && data.defaultBookingMode !== "autoConfirm") {
    throw new HttpsError("invalid-argument", "defaultBookingMode must be 'requiresTutorApproval' or 'autoConfirm'.");
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
}

export const updatePlatformConfig = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const adminUid = requireAdmin(request);
    const data = request.data as Partial<UpdatePlatformConfigRequest>;

    validateUpdatePlatformConfig(data);

    const db = getFirestore();
    const batch = db.batch();

    const configRef = db.collection("quran_session_platform_config").doc("global");
    batch.set(configRef, {
      quranSessionsEnabled: data.quranSessionsEnabled,
      studentEntryEnabled: data.studentEntryEnabled,
      bookingEnabled: data.bookingEnabled,
      sessionMode: data.sessionMode,
      defaultBookingMode: data.defaultBookingMode,
      defaultJoinWindowLeadMs: data.defaultJoinWindowLeadMs,
      defaultTutorApprovalSlaMs: data.defaultTutorApprovalSlaMs,
      defaultMinBookingNoticeMs: data.defaultMinBookingNoticeMs,
      defaultMaxUpcomingPerStudent: data.defaultMaxUpcomingPerStudent,
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
      defaultBookingMode: data.defaultBookingMode,
      defaultJoinWindowLeadMs: data.defaultJoinWindowLeadMs,
      defaultTutorApprovalSlaMs: data.defaultTutorApprovalSlaMs,
      defaultMinBookingNoticeMs: data.defaultMinBookingNoticeMs,
      defaultMaxUpcomingPerStudent: data.defaultMaxUpcomingPerStudent,
    });

    await batch.commit();

    return { success: true };
  }
);
