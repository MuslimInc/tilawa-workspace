import test from "node:test";
import assert from "node:assert/strict";

import { buildOperationKey } from "../../src/quranSessions/idempotencyService";
import {
  financialExecutionStatus,
  PAYMENT_PROVIDER_ENABLED,
} from "../../src/quranSessions/paymentProviderStatus";

test("buildOperationKey is deterministic", () => {
  const key = buildOperationKey("approve_refund", "booking_1", "idem_1");
  assert.equal(key, "approve_refund:booking_1:idem_1");
});

test("financial execution defaults to manual_pending without provider", () => {
  assert.equal(PAYMENT_PROVIDER_ENABLED, false);
  assert.equal(financialExecutionStatus(), "manual_pending");
});
