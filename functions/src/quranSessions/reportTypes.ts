import { FieldValue } from "firebase-admin/firestore";

/**
 * Abuse / safety reports. A report is operational data (an admin work item) and
 * never changes the session lifecycle — it is intentionally decoupled from the
 * dispute flow so a safety concern can be raised regardless of session state.
 */

export type ReportCategory =
  | "safety_concern"
  | "abuse_or_harassment"
  | "inappropriate_content"
  | "child_safety"
  | "fraud_or_scam"
  | "other";

export type ReportStatus = "open" | "under_review" | "resolved" | "dismissed";

const VALID_CATEGORIES: ReadonlySet<string> = new Set<ReportCategory>([
  "safety_concern",
  "abuse_or_harassment",
  "inappropriate_content",
  "child_safety",
  "fraud_or_scam",
  "other",
]);

/** Categories that are escalated for priority review by default. */
const HIGH_SEVERITY_CATEGORIES: ReadonlySet<string> = new Set<ReportCategory>([
  "child_safety",
  "abuse_or_harassment",
  "safety_concern",
]);

export function isValidReportCategory(value: unknown): value is ReportCategory {
  return typeof value === "string" && VALID_CATEGORIES.has(value);
}

export function severityForCategory(category: ReportCategory): "high" | "normal" {
  return HIGH_SEVERITY_CATEGORIES.has(category) ? "high" : "normal";
}

export interface SessionReportRecord {
  reportId: string;
  bookingId: string | null;
  sessionId: string | null;
  aggregateId: string | null;
  reportedUserId: string | null;
  reporterUserId: string;
  reporterRole: string;
  category: ReportCategory;
  description: string;
  severity: "high" | "normal";
  evidenceMetadata: Record<string, unknown> | null;
  status: ReportStatus;
  createdAt: FirebaseFirestore.FieldValue;
  updatedAt: FirebaseFirestore.FieldValue;
}

export function initialReportRecord(input: {
  reportId: string;
  bookingId: string | null;
  sessionId: string | null;
  aggregateId: string | null;
  reportedUserId: string | null;
  reporterUserId: string;
  reporterRole: string;
  category: ReportCategory;
  description: string;
  evidenceMetadata?: Record<string, unknown>;
}): SessionReportRecord {
  return {
    reportId: input.reportId,
    bookingId: input.bookingId,
    sessionId: input.sessionId,
    aggregateId: input.aggregateId,
    reportedUserId: input.reportedUserId,
    reporterUserId: input.reporterUserId,
    reporterRole: input.reporterRole,
    category: input.category,
    description: input.description,
    severity: severityForCategory(input.category),
    evidenceMetadata: input.evidenceMetadata ?? null,
    status: "open",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export type ReportResolution = "under_review" | "resolved" | "dismissed";

const VALID_RESOLUTIONS: ReadonlySet<string> = new Set<ReportResolution>([
  "under_review",
  "resolved",
  "dismissed",
]);

export function isValidReportResolution(value: unknown): value is ReportResolution {
  return typeof value === "string" && VALID_RESOLUTIONS.has(value);
}
