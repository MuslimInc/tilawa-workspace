import { Timestamp, FieldValue } from "firebase-admin/firestore";

export type LifecycleStatus =
  | "draft"
  | "pending_payment"
  | "scheduled"
  | "confirmed"
  | "in_progress"
  | "rescheduled"
  | "cancelled_by_student"
  | "cancelled_by_teacher"
  | "cancelled_by_admin"
  | "teacher_no_show"
  | "student_no_show"
  | "both_no_show"
  | "incomplete"
  | "completed"
  | "disputed"
  | "compensated"
  | "refunded"
  | "expired";

export function legacyStatusForLifecycle(status: LifecycleStatus): string {
  switch (status) {
    case "pending_payment":
      return "pending";
    case "scheduled":
    case "confirmed":
      return "confirmed";
    case "completed":
      return "completed";
    case "refunded":
      return "refunded";
    case "expired":
      return "rejected";
    case "cancelled_by_student":
    case "cancelled_by_teacher":
    case "cancelled_by_admin":
      return "cancelled";
    case "teacher_no_show":
    case "student_no_show":
    case "both_no_show":
      return "no_show";
    default:
      return "pending";
  }
}

export function parseTimestamp(value: unknown): Timestamp {
  if (value instanceof Timestamp) {
    return value;
  }
  if (typeof value === "string") {
    return Timestamp.fromDate(new Date(value));
  }
  throw new Error("Invalid timestamp");
}

export function nowServer() {
  return FieldValue.serverTimestamp();
}
