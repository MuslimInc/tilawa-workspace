/**
 * Production payment integration gate.
 *
 * Paid bookings, automated refunds, and teacher payouts stay disabled until a
 * real provider is wired. Refunds/compensations record manual_pending execution.
 *
 * Default: **false** — paid booking blocked in prod/default env.
 */
export { isPaymentProviderEnabled } from "./payment/envGate";
import { isPaymentProviderEnabled } from "./payment/envGate";

export interface PaidBookingMarketGate {
  manualPaymentEnabled?: boolean;
  paymentProviderEnabled?: boolean;
}

export function assertPaidBookingAllowedForMarket(
  pricingType: string,
  gate: PaidBookingMarketGate = {},
): void {
  if (pricingType === "free") {
    return;
  }
  const paymentProviderEnabled =
    gate.paymentProviderEnabled ?? isPaymentProviderEnabled();
  if (!gate.manualPaymentEnabled && !paymentProviderEnabled) {
    throw new Error("payment_provider_unavailable");
  }
}

export function assertPaidBookingAllowed(
  pricingType: string,
  gate: PaidBookingMarketGate = {},
): void {
  assertPaidBookingAllowedForMarket(pricingType, gate);
}

export type FinancialExecutionStatus = "manual_pending" | "executed" | "failed";

export function financialExecutionStatus(): FinancialExecutionStatus {
  return isPaymentProviderEnabled() ? "executed" : "manual_pending";
}
