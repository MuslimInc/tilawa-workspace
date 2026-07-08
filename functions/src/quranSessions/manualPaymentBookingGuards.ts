import { HttpsError } from "firebase-functions/v2/https";

import { lifecycleError } from "./lifecycleErrors";

export function assertManualOffAppPaymentProvider(
  booking: Record<string, unknown>,
): void {
  if (booking.paymentProvider !== "manual_off_app") {
    throw new HttpsError(
      "failed-precondition",
      "Booking does not use manual off-app payment.",
    );
  }
}

export function assertPendingManualPayment(
  booking: Record<string, unknown>,
): void {
  if (booking.lifecycleStatus !== "pending_payment") {
    throw lifecycleError(
      "invalid_transition",
      "Booking is not awaiting manual payment.",
      { lifecycleStatus: booking.lifecycleStatus },
    );
  }
}
