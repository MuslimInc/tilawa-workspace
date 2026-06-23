import { isPaymentProviderEnabled } from "./envGate";
import { DisabledPaymentProvider } from "./disabledPaymentProvider";
import { SandboxPaymentProvider } from "./sandboxPaymentProvider";
import type { PaymentProvider } from "./types";

let cachedProvider: PaymentProvider | undefined;

export function resolvePaymentProvider(): PaymentProvider {
  if (!isPaymentProviderEnabled()) {
    cachedProvider = new DisabledPaymentProvider();
    return cachedProvider;
  }
  if (!cachedProvider || cachedProvider.kind === "none") {
    cachedProvider = new SandboxPaymentProvider();
  }
  return cachedProvider;
}

/** Test-only reset. */
export function resetPaymentProviderCache(): void {
  cachedProvider = undefined;
}

export function computePlatformFee(amount: number): number {
  // Paid v1: commission from market config — 0 until configured.
  return 0;
}

export function computeTeacherAmount(
  amount: number,
  platformFee: number,
  tax: number,
): number {
  return Math.max(0, amount - platformFee - tax);
}
