import test from "node:test";
import assert from "node:assert/strict";

import {
  assertManualOffAppPaymentProvider,
  assertPendingManualPayment,
} from "../../src/quranSessions/manualPaymentBookingGuards";

test("manual payment guard accepts pending manual booking", () => {
  const booking = {
    paymentProvider: "manual_off_app",
    lifecycleStatus: "pending_payment",
  };

  assert.doesNotThrow(() => assertManualOffAppPaymentProvider(booking));
  assert.doesNotThrow(() => assertPendingManualPayment(booking));
});

test("manual payment guard rejects non-manual booking", () => {
  assert.throws(
    () => assertManualOffAppPaymentProvider({ paymentProvider: "sandbox" }),
    /manual off-app payment/,
  );
});

test("manual payment guard rejects non-pending lifecycle", () => {
  assert.throws(
    () =>
      assertPendingManualPayment({
        paymentProvider: "manual_off_app",
        lifecycleStatus: "scheduled",
      }),
    (error: { details?: { code?: string } }) =>
      error.details?.code === "invalid_transition",
  );
});
