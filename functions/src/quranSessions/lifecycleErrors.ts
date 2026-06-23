import { HttpsError } from "firebase-functions/v2/https";

export type LifecycleErrorCode =
  | "invalid_transition"
  | "unauthorized_actor"
  | "reason_required"
  | "slot_unavailable"
  | "late_student_cancellation_blocked"
  | "not_participant"
  | "payment_provider_unavailable"
  // Booking eligibility (server-side parity with ValidateBookingEligibilityUseCase).
  | "account_blocked"
  | "profile_incomplete"
  | "market_not_enabled"
  | "teacher_not_verified"
  | "gender_not_allowed"
  | "age_not_allowed"
  | "guardian_approval_required"
  | "meeting_link_required"
  | "group_booking_not_supported"
  | "unsupported_session_mode"
  | "unsupported_call_provider";

export function lifecycleError(
  code: LifecycleErrorCode,
  message: string,
  details?: Record<string, unknown>,
): HttpsError {
  const httpCode = code === "unauthorized_actor" || code === "not_participant"
    ? "permission-denied"
    : code === "slot_unavailable"
      ? "already-exists"
      : code === "payment_provider_unavailable"
        ? "failed-precondition"
        : "failed-precondition";

  return new HttpsError(httpCode, message, { code, ...details });
}
