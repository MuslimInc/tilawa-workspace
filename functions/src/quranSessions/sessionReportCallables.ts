import { createHash } from "crypto";

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { appendAuditEvent } from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { lifecycleError } from "./lifecycleErrors";
import {
  initialReportRecord,
  isValidReportCategory,
  isValidReportResolution,
  type ReportCategory,
} from "./reportTypes";
import {
  isAdmin,
  requireAdmin,
  requireAuthenticatedUid,
  requireValidSessionEpochUnlessAdmin,
} from "./sessionAuth";
import { resolveTeacherProfileUserId } from "./teacherProfileUserId";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

interface ReportSessionConcernRequest {
  category: ReportCategory;
  description: string;
  bookingId?: string;
  reportedUserId?: string;
  evidenceMetadata?: Record<string, unknown>;
  idempotencyKey?: string;
}

function shortContentHash(category: string, description: string): string {
  return createHash("sha1")
    .update(`${category}::${description}`)
    .digest("hex")
    .slice(0, 16);
}

/**
 * Files an abuse / safety report. Any authenticated user may file; when the
 * report targets a specific booking the caller must be a participant, the
 * student's guardian, or an admin. Reports are write-only for clients (rules)
 * and surface to admins as a work queue.
 */
export const reportSessionConcern = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);
    const data = request.data as ReportSessionConcernRequest;

    if (!isValidReportCategory(data.category)) {
      throw new HttpsError("invalid-argument", "A valid category is required.");
    }
    if (!data.description?.trim()) {
      throw new HttpsError("invalid-argument", "description is required.");
    }

    const db = getFirestore();

    let bookingId: string | null = null;
    let sessionId: string | null = null;
    let aggregateId: string | null = null;
    let reportedUserId: string | null = data.reportedUserId ?? null;
    let reporterRole = isAdmin(request) ? "admin" : "user";

    if (data.bookingId) {
      const bookingSnap = await db
        .collection("quran_bookings")
        .doc(data.bookingId)
        .get();
      if (!bookingSnap.exists) {
        throw new HttpsError("not-found", "Booking not found.");
      }
      const booking = bookingSnap.data() ?? {};
      const studentId = (booking.studentId as string | undefined) ?? "";
      const teacherProfileId = (booking.teacherId as string | undefined) ?? "";
      const teacherUserId = teacherProfileId
        ? await resolveTeacherProfileUserId(db, teacherProfileId)
        : "";
      bookingId = data.bookingId;
      sessionId = (booking.sessionId as string | undefined) ?? null;
      aggregateId = (booking.aggregateId as string | undefined) ?? data.bookingId;

      if (isAdmin(request)) {
        reporterRole = "admin";
      } else if (uid === studentId) {
        reporterRole = "student";
      } else if (uid === teacherUserId) {
        reporterRole = "teacher";
      } else {
        // Allow a child's guardian to report on their behalf.
        const studentDoc = await db.collection("users").doc(studentId).get();
        const guardianId = (
          studentDoc.data()?.quranSessionsProfile as
            | Record<string, unknown>
            | undefined
        )?.guardianId;
        if (guardianId === uid) {
          reporterRole = "guardian";
        } else {
          throw lifecycleError(
            "not_participant",
            "Caller is not a participant of this booking.",
            { actorId: uid },
          );
        }
      }

      // Default the reported party to the counterparty when not specified.
      if (!reportedUserId) {
        if (uid === studentId) reportedUserId = teacherUserId || null;
        else if (uid === teacherUserId) reportedUserId = studentId || null;
      }
    }

    const scope = data.bookingId ?? reportedUserId ?? uid;
    const suffix =
      data.idempotencyKey?.trim() ||
      shortContentHash(data.category, data.description);
    const operationKey = buildOperationKey("report_concern", scope, suffix);

    const { result } = await runIdempotentOperation(
      { db, operationKey, actorId: uid, action: "report_concern" },
      async (tx) => {
        const reportRef = db.collection("quran_session_reports").doc();
        tx.set(
          reportRef,
          initialReportRecord({
            reportId: reportRef.id,
            bookingId,
            sessionId,
            aggregateId,
            reportedUserId,
            reporterUserId: uid,
            reporterRole,
            category: data.category,
            description: data.description.trim(),
            evidenceMetadata: data.evidenceMetadata,
          }),
        );

        appendAuditEvent(tx, db, {
          aggregateId,
          bookingId,
          sessionId,
          reportId: reportRef.id,
          actorId: uid,
          actorRole: reporterRole,
          action: "report_concern",
          reason: data.category,
          source: reporterRole === "admin" ? "adminPanel" : "mobileApp",
        });

        return { reportId: reportRef.id, status: "open" as const };
      },
    );

    return result;
  },
);

interface ResolveSessionReportRequest {
  reportId: string;
  resolution: "under_review" | "resolved" | "dismissed";
  reason?: string;
  idempotencyKey?: string;
}

/** Admin-only: advances a report to under_review / resolved / dismissed. */
export const resolveSessionReport = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const uid = requireAdmin(request);
    const data = request.data as ResolveSessionReportRequest;

    if (!data.reportId || !isValidReportResolution(data.resolution)) {
      throw new HttpsError(
        "invalid-argument",
        "reportId and a valid resolution are required.",
      );
    }
    const isTerminal = data.resolution !== "under_review";
    if (isTerminal && !data.reason?.trim()) {
      throw new HttpsError(
        "invalid-argument",
        "reason is required to resolve or dismiss a report.",
      );
    }

    const db = getFirestore();
    const reportRef = db.collection("quran_session_reports").doc(data.reportId);
    const reportSnap = await reportRef.get();
    if (!reportSnap.exists) {
      throw new HttpsError("not-found", "Report not found.");
    }
    const report = reportSnap.data() ?? {};

    const operationKey = buildOperationKey(
      "resolve_report",
      data.reportId,
      data.idempotencyKey ?? data.resolution,
    );

    const { result } = await runIdempotentOperation(
      { db, operationKey, actorId: uid, action: "resolve_report" },
      async (tx) => {
        tx.set(
          reportRef,
          {
            status: data.resolution,
            updatedAt: FieldValue.serverTimestamp(),
            ...(isTerminal
              ? {
                  resolutionReason: data.reason,
                  resolvedByUserId: uid,
                  resolvedAt: FieldValue.serverTimestamp(),
                }
              : {}),
          },
          { merge: true },
        );

        appendAuditEvent(tx, db, {
          aggregateId: report.aggregateId ?? null,
          bookingId: report.bookingId ?? null,
          sessionId: report.sessionId ?? null,
          reportId: data.reportId,
          actorId: uid,
          actorRole: "admin",
          action: "resolve_report",
          reason: data.reason ?? data.resolution,
          resolution: data.resolution,
          source: "adminPanel",
        });

        return { reportId: data.reportId, status: data.resolution };
      },
    );

    return result;
  },
);
