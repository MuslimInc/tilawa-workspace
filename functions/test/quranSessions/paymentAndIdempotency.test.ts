import test from "node:test";
import assert from "node:assert/strict";

import { buildOperationKey } from "../../src/quranSessions/idempotencyService";
import { isPaymentProviderEnabled } from "../../src/quranSessions/payment/envGate";
import { financialExecutionStatus } from "../../src/quranSessions/paymentProviderStatus";
import { resolvePaymentProvider } from "../../src/quranSessions/payment/paymentProviderRegistry";
import { DisabledPaymentProvider } from "../../src/quranSessions/payment/disabledPaymentProvider";

test("buildOperationKey is deterministic", () => {
  const key = buildOperationKey("approve_refund", "booking_1", "idem_1");
  assert.equal(key, "approve_refund:booking_1:idem_1");
});

test("financial execution defaults to manual_pending without provider", () => {
  assert.equal(isPaymentProviderEnabled(), false);
  assert.equal(financialExecutionStatus(), "manual_pending");
});

test("resolvePaymentProvider returns disabled provider by default", () => {
  const provider = resolvePaymentProvider();
  assert.ok(provider instanceof DisabledPaymentProvider);
  assert.equal(provider.kind, "none");
});
