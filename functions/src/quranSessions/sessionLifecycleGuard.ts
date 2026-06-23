import { lifecycleError } from "./lifecycleErrors";
import type { LifecycleStatus } from "./sessionLifecycleService";

export type ActorRole = "student" | "teacher" | "admin" | "system";

export type SessionAction =
  | "create_draft"
  | "initiate_payment"
  | "confirm_booking"
  | "confirm_free_booking"
  | "acknowledge_session"
  | "start_session"
  | "complete_session"
  | "request_reschedule"
  | "confirm_reschedule"
  | "admin_force_reschedule"
  | "cancel_by_student"
  | "cancel_by_teacher"
  | "cancel_by_admin"
  | "mark_teacher_no_show"
  | "mark_student_no_show"
  | "mark_both_no_show"
  | "mark_incomplete"
  | "open_dispute"
  | "issue_compensation"
  | "issue_refund"
  | "expire_reservation"
  | "reject_booking";

export interface SessionTransition {
  action: SessionAction;
  from: ReadonlySet<LifecycleStatus | null>;
  to: LifecycleStatus;
  allowedActors: ReadonlySet<ActorRole>;
  requiresReason: boolean;
}

const ALL_STATUSES: ReadonlySet<LifecycleStatus> = new Set([
  "draft",
  "pending_payment",
  "scheduled",
  "confirmed",
  "in_progress",
  "rescheduled",
  "cancelled_by_student",
  "cancelled_by_teacher",
  "cancelled_by_admin",
  "teacher_no_show",
  "student_no_show",
  "both_no_show",
  "incomplete",
  "completed",
  "disputed",
  "compensated",
  "refunded",
  "expired",
]);

const TRANSITIONS: readonly SessionTransition[] = [
  {
    action: "create_draft",
    from: new Set([null]),
    to: "draft",
    allowedActors: new Set(["student"]),
    requiresReason: false,
  },
  {
    action: "initiate_payment",
    from: new Set(["draft"]),
    to: "pending_payment",
    allowedActors: new Set(["student"]),
    requiresReason: false,
  },
  {
    action: "confirm_booking",
    from: new Set(["pending_payment"]),
    to: "scheduled",
    allowedActors: new Set(["system"]),
    requiresReason: false,
  },
  {
    action: "confirm_free_booking",
    from: new Set(["draft"]),
    to: "scheduled",
    allowedActors: new Set(["student", "system"]),
    requiresReason: false,
  },
  {
    action: "acknowledge_session",
    from: new Set(["scheduled"]),
    to: "confirmed",
    allowedActors: new Set(["student", "teacher"]),
    requiresReason: false,
  },
  {
    action: "start_session",
    from: new Set(["scheduled", "confirmed"]),
    to: "in_progress",
    allowedActors: new Set(["system", "teacher"]),
    requiresReason: false,
  },
  {
    action: "complete_session",
    from: new Set(["in_progress"]),
    to: "completed",
    allowedActors: new Set(["system", "teacher", "student"]),
    requiresReason: false,
  },
  {
    action: "request_reschedule",
    from: new Set(["scheduled", "confirmed"]),
    to: "rescheduled",
    allowedActors: new Set(["student", "teacher"]),
    requiresReason: true,
  },
  {
    action: "confirm_reschedule",
    from: new Set(["rescheduled"]),
    to: "scheduled",
    allowedActors: new Set(["student", "teacher", "system"]),
    requiresReason: true,
  },
  {
    action: "admin_force_reschedule",
    from: new Set(["scheduled", "confirmed"]),
    to: "scheduled",
    allowedActors: new Set(["admin"]),
    requiresReason: true,
  },
  {
    action: "cancel_by_student",
    from: new Set(["scheduled", "confirmed", "pending_payment"]),
    to: "cancelled_by_student",
    allowedActors: new Set(["student"]),
    requiresReason: true,
  },
  {
    action: "cancel_by_teacher",
    from: new Set(["scheduled", "confirmed"]),
    to: "cancelled_by_teacher",
    allowedActors: new Set(["teacher"]),
    requiresReason: true,
  },
  {
    action: "cancel_by_admin",
    from: new Set([
      "draft",
      "pending_payment",
      "scheduled",
      "confirmed",
      "in_progress",
      "rescheduled",
    ]),
    to: "cancelled_by_admin",
    allowedActors: new Set(["admin"]),
    requiresReason: true,
  },
  {
    action: "mark_teacher_no_show",
    from: new Set(["scheduled", "confirmed", "in_progress"]),
    to: "teacher_no_show",
    allowedActors: new Set(["admin", "system"]),
    requiresReason: false,
  },
  {
    action: "mark_student_no_show",
    from: new Set(["scheduled", "confirmed", "in_progress"]),
    to: "student_no_show",
    allowedActors: new Set(["admin", "system", "teacher"]),
    requiresReason: false,
  },
  {
    action: "mark_both_no_show",
    from: new Set(["scheduled", "confirmed", "in_progress"]),
    to: "both_no_show",
    allowedActors: new Set(["system"]),
    requiresReason: false,
  },
  {
    action: "mark_incomplete",
    from: new Set(["in_progress"]),
    to: "incomplete",
    allowedActors: new Set(["system"]),
    requiresReason: false,
  },
  {
    action: "open_dispute",
    from: new Set([
      "completed",
      "cancelled_by_student",
      "cancelled_by_teacher",
      "cancelled_by_admin",
      "teacher_no_show",
      "student_no_show",
      "both_no_show",
    ]),
    to: "disputed",
    allowedActors: new Set(["student", "teacher", "admin"]),
    requiresReason: true,
  },
  {
    action: "issue_compensation",
    from: new Set(["disputed", "cancelled_by_teacher", "teacher_no_show"]),
    to: "compensated",
    allowedActors: new Set(["admin", "system"]),
    requiresReason: true,
  },
  {
    action: "issue_refund",
    from: ALL_STATUSES,
    to: "refunded",
    allowedActors: new Set(["admin", "system"]),
    requiresReason: true,
  },
  {
    action: "expire_reservation",
    from: new Set(["draft", "pending_payment"]),
    to: "expired",
    allowedActors: new Set(["system"]),
    requiresReason: false,
  },
  {
    action: "reject_booking",
    from: new Set(["pending_payment"]),
    to: "expired",
    allowedActors: new Set(["system"]),
    requiresReason: false,
  },
];

export interface GuardInput {
  currentStatus: LifecycleStatus | null | undefined;
  action: SessionAction;
  actor: ActorRole;
  reason?: string;
  sessionStartsAt?: Date;
  isTargetSlotAvailable?: boolean;
  targetSlotId?: string;
}

export interface GuardResult {
  to: LifecycleStatus;
  transition: SessionTransition;
}

const STUDENT_CANCEL_MIN_NOTICE_MS = 60 * 60 * 1000;

function isBlank(value: string | undefined): boolean {
  return value == null || value.trim().length === 0;
}

function resolveTransition(
  currentStatus: LifecycleStatus | null | undefined,
  action: SessionAction,
): SessionTransition | null {
  const normalized = currentStatus ?? null;
  for (const candidate of TRANSITIONS) {
    if (!candidate.from.has(normalized)) {
      continue;
    }
    if (candidate.action === action) {
      return candidate;
    }
  }
  return null;
}

export function validateTransition(input: GuardInput): GuardResult {
  const transition = resolveTransition(input.currentStatus, input.action);
  if (transition == null) {
    throw lifecycleError("invalid_transition", "Lifecycle transition not allowed.", {
      action: input.action,
      actorRole: input.actor,
      currentStatus: input.currentStatus ?? null,
    });
  }

  if (!transition.allowedActors.has(input.actor)) {
    throw lifecycleError("unauthorized_actor", "Actor not allowed for this action.", {
      action: input.action,
      actorRole: input.actor,
      allowedActorRoles: [...transition.allowedActors],
      currentStatus: input.currentStatus ?? null,
    });
  }

  if (transition.requiresReason && isBlank(input.reason)) {
    throw lifecycleError("reason_required", "Reason is required for this action.", {
      action: input.action,
    });
  }

  if (
    input.action === "confirm_reschedule" &&
    input.isTargetSlotAvailable === false
  ) {
    throw lifecycleError("slot_unavailable", "Target slot is unavailable.", {
      targetSlotId: input.targetSlotId ?? "unknown_slot",
    });
  }

  if (
    input.action === "cancel_by_student" &&
    input.sessionStartsAt != null
  ) {
    const remaining = input.sessionStartsAt.getTime() - Date.now();
    if (remaining < STUDENT_CANCEL_MIN_NOTICE_MS) {
      throw lifecycleError(
        "late_student_cancellation_blocked",
        "Student cancellation blocked within minimum notice window.",
        {
          action: input.action,
          actorRole: input.actor,
          currentStatus: input.currentStatus ?? null,
          reasonCode: "late_student_cancellation_blocked",
        },
      );
    }
  }

  return { to: transition.to, transition };
}

export function noShowActionForClassification(
  classification: "teacher_no_show" | "student_no_show" | "both_no_show",
): SessionAction {
  switch (classification) {
    case "teacher_no_show":
      return "mark_teacher_no_show";
    case "student_no_show":
      return "mark_student_no_show";
    case "both_no_show":
      return "mark_both_no_show";
  }
}

export function cancelActionForRole(role: ActorRole): SessionAction {
  switch (role) {
    case "teacher":
      return "cancel_by_teacher";
    case "admin":
    case "system":
      return "cancel_by_admin";
    default:
      return "cancel_by_student";
  }
}

export function allTransitions(): readonly SessionTransition[] {
  return TRANSITIONS;
}
