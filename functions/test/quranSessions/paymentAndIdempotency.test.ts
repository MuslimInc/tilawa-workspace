import test from "node:test";
import assert from "node:assert/strict";

import { buildOperationKey } from "../../src/quranSessions/idempotencyService";
import { isPaymentProviderEnabled } from "../../src/quranSessions/payment/envGate";
import { generateManualPaymentReference } from "../../src/quranSessions/manualPaymentReference";
import {
  assertPaidBookingAllowed,
  assertPaidBookingAllowedForMarket,
  financialExecutionStatus,
} from "../../src/quranSessions/paymentProviderStatus";
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

test("assertPaidBookingAllowed rejects paid bookings while provider disabled", () => {
  assert.equal(isPaymentProviderEnabled(), false);
  assert.doesNotThrow(() => assertPaidBookingAllowed("free"));
  assert.throws(
    () => assertPaidBookingAllowed("fixedPerSession"),
    /payment_provider_unavailable/,
  );
});

test("assertPaidBookingAllowedForMarket permits manual paid bookings", () => {
  assert.doesNotThrow(() =>
    assertPaidBookingAllowedForMarket("fixedPerSession", {
      manualPaymentEnabled: true,
      paymentProviderEnabled: false,
    }),
  );
});

test("generateManualPaymentReference is deterministic and human-readable", () => {
  const bookingId = "booking_abc123xyz789";
  const ref = generateManualPaymentReference(bookingId);

  assert.equal(ref, generateManualPaymentReference(bookingId));
  assert.match(ref, /^QS-[A-Z0-9-]+$/);
  assert.equal(generateManualPaymentReference("abc123"), "QS-ABC1-23");
});

test("assertPaidBookingAllowed permits paid bookings when the gate is on", () => {
  process.env.QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED = "true";
  try {
    assert.doesNotThrow(() => assertPaidBookingAllowed("fixedPerSession"));
  } finally {
    delete process.env.QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED;
  }
});
