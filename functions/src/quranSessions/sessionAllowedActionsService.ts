import type { ActorRole } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import { isWithinJoinWindow } from "./sessionJoinWindowPolicy";

/** Q-SR-02 — mirrors Dart `SessionAllowedAction`. */
export type SessionAllowedAction =
  | "join"
  | "cancel"
  | "reschedule"
  | "reportConcern"
  | "openDispute"
  | "submitReview"
  | "respondToBookingRequest";

export interface AllowedActionsInput {
  lifecycleStatus: LifecycleStatus | string;
  actorRole: ActorRole;
  startsAt: Date;
  endsAt: Date;
  now?: Date;
  joinWindowLeadMs?: number;
  hasPendingReschedule?: boolean;
}

const JOINABLE_STATUSES = new Set<string>([
  "scheduled",
  "confirmed",
  "in_progress",
  "rescheduled",
]);

const CANCELLABLE_BY_STUDENT = new Set<string>([
  "scheduled",
  "confirmed",
  "pending_payment",
  "pending_tutor_approval",
]);

const CANCELLABLE_BY_TEACHER = new Set<string>(["scheduled", "confirmed"]);

const RESCHEDULABLE = new Set<string>(["scheduled", "confirmed"]);

const DISPUTABLE = new Set<string>([
  "completed",
  "cancelled_by_student",
  "cancelled_by_teacher",
  "cancelled_by_admin",
  "teacher_no_show",
  "student_no_show",
  "both_no_show",
]);

const REVIEWABLE = new Set<string>(["completed"]);

export function resolveSessionAllowedActions(
  input: AllowedActionsInput,
): SessionAllowedAction[] {
  const now = input.now ?? new Date();
  const status = input.lifecycleStatus;
  const actions: SessionAllowedAction[] = [];

  if (
    JOINABLE_STATUSES.has(status) &&
    isWithinJoinWindow({
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      now,
      leadTimeMs: input.joinWindowLeadMs,
    })
  ) {
    actions.push("join");
  }

  if (input.actorRole === "student" && CANCELLABLE_BY_STUDENT.has(status)) {
    actions.push("cancel");
  }
  if (input.actorRole === "teacher" && CANCELLABLE_BY_TEACHER.has(status)) {
    actions.push("cancel");
  }

  if (
    RESCHEDULABLE.has(status) &&
    (input.actorRole === "student" || input.actorRole === "teacher") &&
    !input.hasPendingReschedule
  ) {
    actions.push("reschedule");
  }

  if (input.actorRole === "teacher" && status === "pending_tutor_approval") {
    actions.push("respondToBookingRequest");
  }

  actions.push("reportConcern");

  if (DISPUTABLE.has(status)) {
    actions.push("openDispute");
  }

  if (REVIEWABLE.has(status) && input.actorRole === "student") {
    actions.push("submitReview");
  }

  return actions;
}

export function allowedActionsForParticipant(
  input: Omit<AllowedActionsInput, "actorRole"> & {
    studentId: string;
    teacherUserId: string;
    viewerUserId: string;
  },
): SessionAllowedAction[] {
  let actorRole: ActorRole = "student";
  if (input.viewerUserId === input.teacherUserId) {
    actorRole = "teacher";
  } else if (input.viewerUserId !== input.studentId) {
    return [];
  }
  return resolveSessionAllowedActions({ ...input, actorRole });
}

export function buildAllowedActionsDenorm(params: {
  studentId: string;
  teacherUserId: string;
  lifecycleStatus: LifecycleStatus | string;
  startsAt: Date;
  endsAt: Date;
  joinWindowLeadMs?: number;
}): Record<string, unknown> {
  const studentActions = resolveSessionAllowedActions({
    lifecycleStatus: params.lifecycleStatus,
    actorRole: "student",
    startsAt: params.startsAt,
    endsAt: params.endsAt,
    joinWindowLeadMs: params.joinWindowLeadMs,
  });
  const teacherActions = resolveSessionAllowedActions({
    lifecycleStatus: params.lifecycleStatus,
    actorRole: "teacher",
    startsAt: params.startsAt,
    endsAt: params.endsAt,
    joinWindowLeadMs: params.joinWindowLeadMs,
  });
  return {
    allowedActionsStudent: studentActions,
    allowedActionsTeacher: teacherActions,
    allowedActionsUpdatedAt: new Date().toISOString(),
  };
}
