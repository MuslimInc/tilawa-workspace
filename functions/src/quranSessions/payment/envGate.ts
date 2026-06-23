/** Runtime payment provider env gate (evaluated at call time). */
export function isPaymentProviderEnabled(): boolean {
  return process.env.QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED === "true";
}
