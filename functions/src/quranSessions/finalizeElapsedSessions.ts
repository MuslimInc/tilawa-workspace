import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import {
  appendAuditEvent,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import { buildOperationKey, runIdempotentOperation } from "./idempotencyService";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import {
  resolveTeacherProfileUserId,
  teacherUserIdFromDenormalizedSessionData,
} from "./teacherProfileUserId";
import { validateTransition, type SessionAction } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";

/**
 * Finalizes sessions whose scheduled end passed without a lifecycle
 * transition. Without this sweep, unattended sessions rot in
 * `scheduled`/`confirmed` forever: they count against the student's
 * max-upcoming booking cap, never surface a terminal state in the client,
 * and never feed no-show metrics.
 *
 * Classification uses the call-tracking aggregate written by
 * `recordCallTelemetryEvent` (quran_sessions/{id}/callTracking/summary):
 *
 * - no telemetry doc            → expired            (no evidence, no penalty)
 * - only teacher ever connected → student_no_show
 * - only student ever connected → teacher_no_show    (compensation-eligible)
 * - neither ever connected      → both_no_show
 * - both connected, ≥50% of the planned duration → completed
 * - both connected, shorter     → incomplete
 */

/// Grace after `endsAt` before finalizing, so a running-over call or a late
/// manual `completeSession` is not raced by the sweep.
export const FINALIZE_GRACE_MS = 30 * 60 * 1000;

/// Both-connected call time required (as a fraction of the planned session
/// duration) for the sweep to auto-complete a session nobody closed out.
export const COMPLETION_MIN_CONNECTED_RATIO = 0.5;

/// Bound the scan; the scheduler re-runs, so a backlog drains across runs.
const FINALIZE_QUERY_LIMIT = 100;

const FINALIZABLE_STATUSES: ReadonlySet<LifecycleStatus> = new Set([
  "scheduled",
  "confirmed",
  "in_progress",
]);

export interface ElapsedSessionEvidence {
  lifecycleStatus: "scheduled" | "confirmed" | "in_progress";
  plannedDurationMs: number;
  /** True when quran_sessions/{id}/callTracking/summary exists. */
  trackingExists: boolean;
  teacherEverConnected: boolean;
  studentEverConnected: boolean;
  bothParticipantsConnectedSeconds: number;
}

export interface ElapsedSessionOutcome {
  action: SessionAction;
  noShowClassification:
    | "teacher_no_show"
    | "student_no_show"
    | "both_no_show"
    | null;
}

/** Pure classification of an elapsed session from its attendance evidence. */
export function classifyElapsedSession(
  evidence: ElapsedSessionEvidence,
): ElapsedSessionOutcome {
  const minConnectedSeconds =
    (evidence.plannedDurationMs / 1000) * COMPLETION_MIN_CONNECTED_RATIO;
  const callLongEnough =
    evidence.bothParticipantsConnectedSeconds >= minConnectedSeconds &&
    evidence.bothParticipantsConnectedSeconds > 0;

  if (evidence.lifecycleStatus === "in_progress") {
    return callLongEnough
      ? { action: "complete_session", noShowClassification: null }
      : { action: "mark_incomplete", noShowClassification: null };
  }

  if (!evidence.trackingExists) {
    return { action: "expire_unattended_session", noShowClassification: null };
  }

  const teacher = evidence.teacherEverConnected;
  const student = evidence.studentEverConnected;
  if (teacher && !student) {
    return {
      action: "mark_student_no_show",
      noShowClassification: "student_no_show",
    };
  }
  if (!teacher && student) {
    return {
      action: "mark_teacher_no_show",
      noShowClassification: "teacher_no_show",
    };
  }
  if (!teacher && !student) {
    return {
      action: "mark_both_no_show",
      noShowClassification: "both_no_show",
    };
  }

  // Both connected but the session was never moved to in_progress.
  return callLongEnough
    ? { action: "finalize_completed_session", noShowClassification: null }
    : { action: "mark_incomplete", noShowClassification: null };
}

function asMillis(raw: unknown): number | null {
  if (raw instanceof Timestamp) return raw.toMillis();
  if (raw && typeof (raw as { toMillis?: unknown }).toMillis === "function") {
    return (raw as { toMillis(): number }).toMillis();
  }
  return null;
}

export const finalizeElapsedSessions = onSchedule(
  "every 10 minutes",
  async () => {
    const db = getFirestore();
    const cutoff = Timestamp.fromMillis(Date.now() - FINALIZE_GRACE_MS);
    const elapsed = await db
      .collection("quran_sessions")
      .where("lifecycleStatus", "in", [...FINALIZABLE_STATUSES])
      .where("endsAt", "<=", cutoff)
      .orderBy("endsAt")
      .limit(FINALIZE_QUERY_LIMIT)
      .get();

    for (const doc of elapsed.docs) {
      try {
        await finalizeSession(db, doc);
      } catch (error) {
        console.error(`Failed to finalize session ${doc.id}:`, error);
      }
    }

    if (!elapsed.empty) {
      console.log(`Finalized ${elapsed.docs.length} elapsed session(s).`);
    }
  },
);

async function finalizeSession(
  db: FirebaseFirestore.Firestore,
  doc: FirebaseFirestore.QueryDocumentSnapshot,
): Promise<void> {
  const sessionRef = doc.ref;
  const trackingRef = sessionRef.collection("callTracking").doc("summary");
  const trackingSnap = await trackingRef.get();
  const tracking = trackingSnap.data() ?? {};

  // Keyed by the endsAt observed at query time: if a reschedule moves the
  // session while this run is in flight, the skipped marker for the old time
  // cannot shadow finalization of the new one.
  const operationKey = buildOperationKey(
    "finalize_elapsed_session",
    doc.id,
    String(asMillis(doc.data().endsAt) ?? "scheduler"),
  );

  const { result, replayed } = await runIdempotentOperation<{
    sessionId: string;
    skipped?: boolean;
    lifecycleStatus?: LifecycleStatus;
    noShowClassification?: string | null;
    teacherId?: string;
    studentId?: string;
    aggregateId?: string;
  }>(
    {
      db,
      operationKey,
      actorId: "system",
      action: "finalize_elapsed_session",
    },
    async (tx) => {
      const fresh = (await tx.get(sessionRef)).data() ?? {};
      const currentStatus = fresh.lifecycleStatus as
        | LifecycleStatus
        | undefined;
      if (
        currentStatus == null ||
        !FINALIZABLE_STATUSES.has(currentStatus)
      ) {
        return { sessionId: doc.id, skipped: true };
      }
      const endsAtMs = asMillis(fresh.endsAt);
      if (endsAtMs == null || Date.now() < endsAtMs + FINALIZE_GRACE_MS) {
        return { sessionId: doc.id, skipped: true };
      }

      const startsAtMs = asMillis(fresh.startsAt);
      const outcome = classifyElapsedSession({
        lifecycleStatus: currentStatus as ElapsedSessionEvidence["lifecycleStatus"],
        plannedDurationMs:
          startsAtMs != null ? Math.max(0, endsAtMs - startsAtMs) : 0,
        trackingExists: trackingSnap.exists,
        teacherEverConnected:
          tracking.firstJoinRole === "teacher" ||
          tracking.secondJoinRole === "teacher",
        studentEverConnected:
          tracking.firstJoinRole === "student" ||
          tracking.secondJoinRole === "student",
        bothParticipantsConnectedSeconds:
          (tracking.bothParticipantsConnectedSeconds as number | undefined) ??
          0,
      });

      const guard = validateTransition({
        currentStatus,
        action: outcome.action,
        actor: "system",
      });

      const bookingId = fresh.bookingId as string | undefined;
      const bookingRef = bookingId
        ? db.collection("quran_bookings").doc(bookingId)
        : undefined;
      writeAggregateLifecycle(
        tx,
        { bookingRef: bookingRef ?? sessionRef, sessionRef },
        guard.to,
        {},
        {},
        fresh,
      );

      appendAuditEvent(tx, db, {
        aggregateId: fresh.aggregateId ?? bookingId ?? doc.id,
        bookingId: bookingId ?? null,
        sessionId: doc.id,
        actorId: "system",
        actorRole: "system",
        action: outcome.action,
        previousStatus: currentStatus,
        newStatus: guard.to,
        classification: outcome.noShowClassification,
        source: "backendJob",
      });

      return {
        sessionId: doc.id,
        lifecycleStatus: guard.to,
        noShowClassification: outcome.noShowClassification,
        teacherId: (fresh.teacherId as string | undefined) ?? "",
        studentId: (fresh.studentId as string | undefined) ?? "",
        aggregateId:
          (fresh.aggregateId as string | undefined) ?? bookingId ?? doc.id,
      };
    },
  );

  if (replayed || result.skipped) return;
  const { teacherId, studentId } = result;
  if (!teacherId || !studentId) return;

  if (result.lifecycleStatus === "completed") {
    await recordTerminalTransition(db, {
      type: "completed",
      teacherId,
      studentId,
    });
  } else if (result.noShowClassification) {
    const classification = result.noShowClassification as
      | "teacher_no_show"
      | "student_no_show"
      | "both_no_show";
    const metricsType =
      classification === "teacher_no_show"
        ? ({ type: "teacher_no_show", teacherId } as const)
        : classification === "student_no_show"
          ? ({ type: "student_no_show", studentId } as const)
          : ({ type: "both_no_show", teacherId, studentId } as const);
    await recordTerminalTransition(db, metricsType);

    const sessionData = doc.data() ?? {};
    const teacherUserId =
      teacherUserIdFromDenormalizedSessionData(sessionData) ??
      (await resolveTeacherProfileUserId(db, teacherId));
    await enqueueSessionNotification(db, {
      sessionId: doc.id,
      aggregateId: result.aggregateId ?? doc.id,
      kind: "noShowMarked",
      recipientUserIds: [teacherUserId, studentId],
      payload: { classification },
    });
  }
}
