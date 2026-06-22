/**
 * Production payment integration gate.
 *
 * Paid bookings, automated refunds, and teacher payouts stay disabled until a
 * real provider is wired. Refunds/compensations record manual_pending execution.
 */
export const PAYMENT_PROVIDER_ENABLED =
  process.env.QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED === "true";

export function assertPaidBookingAllowed(pricingType: string): void {
  if (pricingType === "free") {
    return;
  }
  if (!PAYMENT_PROVIDER_ENABLED) {
    throw new Error("payment_provider_unavailable");
  }
}

export type FinancialExecutionStatus = "manual_pending" | "executed" | "failed";

export function financialExecutionStatus(): FinancialExecutionStatus {
  return PAYMENT_PROVIDER_ENABLED ? "executed" : "manual_pending";
}
