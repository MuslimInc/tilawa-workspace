/**
 * Deterministic policy that maps a package booking's terminal session lifecycle
 * outcome to a single package-credit operation.
 *
 * This is the package-credit analogue of the existing
 * `ConfigurableCompensationPolicy` (which handles pay-per-session
 * wallet/refund). It is pure and framework-free so every lifecycle result is
 * unit-testable; the transactional lifecycle handlers call it and apply the
 * decided operation via {@link packageCreditService} with deterministic
 * movement ids.
 *
 * ## Credit rules (spec E2E B + data-model)
 *
 * | Terminal status         | credit op | extend validity | rationale                    |
 * |-------------------------|-----------|-----------------|------------------------------|
 * | `completed`             | consume   | no              | session delivered            |
 * | `cancelled_by_student`  | see below | no              | cutoff decides restore/consume |
 * | `cancelled_by_teacher`  | restore   | yes             | teacher fault                |
 * | `cancelled_by_admin`    | restore   | no              | goodwill                     |
 * | `teacher_no_show`       | restore   | yes             | teacher fault                |
 * | `student_no_show`       | consume   | no              | learner fault                |
 * | `both_no_show`          | restore   | yes             | teacher also absent          |
 * | `rejected_by_tutor`     | restore   | no              | booking never confirmed      |
 * | `expired`               | restore   | no              | release the reservation      |
 * | `incomplete`            | none      | no              | manual review                |
 * | `disputed`              | none      | no              | resolved by dispute flow     |
 * | `compensated`/`refunded`| none      | no              | handled separately           |
 *
 * `cancelled_by_student` restores the credit when cancelled **before** the
 * protected cutoff, and consumes it (late cancellation) otherwise.
 */

import type { LifecycleStatus } from "../sessionLifecycleService";

export type PackageCreditOp = "consume" | "restore" | "none";

export interface PackageCreditDecision {
  op: PackageCreditOp;
  /** Machine-readable reason recorded on the movement. */
  reasonCode: string;
  /** Extend package validity for the lost session (teacher-fault only). */
  extendValidity: boolean;
  /** Ambiguous outcome — no automatic op; an operator must decide. */
  manualReview: boolean;
}

export interface LifecycleCreditInput {
  status: LifecycleStatus;
  /**
   * For `cancelled_by_student` only: whether the cancellation happened at or
   * after the protected cancellation cutoff (a "late" cancellation).
   */
  lateStudentCancellation?: boolean;
}

const consume = (reasonCode: string): PackageCreditDecision => ({
  op: "consume",
  reasonCode,
  extendValidity: false,
  manualReview: false,
});

const restore = (
  reasonCode: string,
  extendValidity: boolean,
): PackageCreditDecision => ({
  op: "restore",
  reasonCode,
  extendValidity,
  manualReview: false,
});

const none = (reasonCode: string, manualReview: boolean): PackageCreditDecision => ({
  op: "none",
  reasonCode,
  extendValidity: false,
  manualReview,
});

/**
 * Whether a student cancellation is "late" (at or after the protected cutoff).
 * `cutoffHours` before `sessionStartMs` is the boundary; cancelling exactly at
 * the boundary counts as late.
 */
export function isLateStudentCancellation(
  sessionStartMs: number,
  nowMs: number,
  cutoffHours: number,
): boolean {
  const cutoffMs = sessionStartMs - cutoffHours * 60 * 60 * 1000;
  return nowMs >= cutoffMs;
}

/**
 * Decide the credit operation for a terminal (or non-terminal) session status.
 * Non-terminal statuses leave the credit reserved (`op: "none"`,
 * `manualReview: false`).
 */
export function decidePackageCreditForLifecycle(
  input: LifecycleCreditInput,
): PackageCreditDecision {
  switch (input.status) {
    case "completed":
      return consume("session_completed");

    case "cancelled_by_student":
      return input.lateStudentCancellation
        ? consume("late_student_cancellation")
        : restore("student_early_cancellation", false);

    case "cancelled_by_teacher":
      return restore("teacher_cancellation", true);

    case "cancelled_by_admin":
      return restore("admin_cancellation", false);

    case "teacher_no_show":
      return restore("teacher_no_show", true);

    case "student_no_show":
      return consume("student_no_show");

    case "both_no_show":
      return restore("both_no_show", true);

    case "rejected_by_tutor":
      return restore("tutor_rejected_booking", false);

    case "expired":
      return restore("session_expired_unused", false);

    case "incomplete":
      return none("incomplete_needs_review", true);

    case "disputed":
      return none("dispute_pending", true);

    case "compensated":
      return none("compensation_handled_separately", false);

    case "refunded":
      return none("refund_handled_separately", false);

    // Non-terminal / reservation-active states: nothing to finalize yet.
    case "draft":
    case "pending_payment":
    case "pending_tutor_approval":
    case "scheduled":
    case "confirmed":
    case "in_progress":
    case "rescheduled":
      return none("reservation_active", false);
  }
}
