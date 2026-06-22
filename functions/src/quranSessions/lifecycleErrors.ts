import { HttpsError } from "firebase-functions/v2/https";

export type LifecycleErrorCode =
  | "invalid_transition"
  | "unauthorized_actor"
  | "reason_required"
  | "slot_unavailable"
  | "late_student_cancellation_blocked"
  | "not_participant"
  | "payment_provider_unavailable";

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
